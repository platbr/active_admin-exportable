# frozen_string_literal: true

module ActiveAdmin
  module Exportable
    class Importer
      def initialize(path: nil, data: nil, json: nil, yaml: nil, allow_update: false, ignore_ids: false, format: nil)
        @data = data if data.present?
        @data ||= path_to_data(path, format: format) if path.present?
        @data ||= json_to_data(json) if json.present?
        @data ||= yaml_to_data(yaml) if yaml.present?
        @allow_update = allow_update
        @ignore_ids = ignore_ids
      end

      def import
        ActiveRecord::Base.transaction do
          process_associations_content(@data)
        end
      end

      private

      def path_to_data(path, format: nil)
        format ||= path.match(/.(?<format>\w+)$/)[:format]
        case format.to_s
        when 'json'
          json_to_data(File.open(path).read)
        when 'yaml'
          yaml_to_data(File.open(path).read)
        end
      end

      def json_to_data(json)
        JSON.parse(json)
      end

      def yaml_to_data(yaml)
        YAML.safe_load(yaml)
      end

      def process_associations_content(content, relation: nil, relation_name: nil)
        if content.is_a?(Array)
          content.each do |c|
            process_data(c.with_indifferent_access, relation: relation, relation_name: relation_name)
          end
        else
          process_data(content.with_indifferent_access, relation: relation, relation_name: relation_name)
        end
      end

      def process_data(data, relation: nil, relation_name: nil)
        record = update_or_create_record_from_data(data)
        assign_relation_if_needed(record, relation, relation_name)
        create_and_assign_belongs_to_associations(record, data)
        record.save!
        create_non_belongs_to_associations(record, data)
        record
      rescue StandardError => e
        raise "#{e.message} - details: #{record.inspect}"
      end

      def update_or_create_record_from_data(data)
        record = find_or_initialize_from_data(data)
        return record if !@allow_update && !record.new_record?

        record.attributes = data[:attributes]
        record
      end

      def find_or_initialize_from_data(data)
        klass = data[:class_name].constantize
        data[:attributes][:id] = nil if @ignore_ids
        where_opts = if data[:attributes][:id].present?
                       { id: data[:attributes][:id] }
                     elsif klass.respond_to?(:exportable_search_attributes)
                       klass.exportable_search_attributes.to_h { |x| [x, data[:attributes][x]] }
                     end
        record = klass.where(where_opts).take if where_opts.present?
        record || klass.new
      end

      def assign_relation_if_needed(record, relation, relation_name)
        record.send("#{relation_name}=", relation) if relation.present?
      end

      def create_and_assign_belongs_to_associations(record, data)
        filter_belongs_to_associations(data).each do |association_data|
          association_record = process_data(association_data[:content])
          record.send("#{association_data[:name]}=", association_record)
        end
      end

      def create_non_belongs_to_associations(record, data)
        filter_non_belongs_to_associations(data).each do |association_data|
          process_associations_content(association_data[:content], relation: record,
                                                                   relation_name: association_data[:inverse])
        end
      end

      def filter_belongs_to_associations(data)
        data[:associations].select { |a| a[:kind] == 'belongs_to' }
      end

      def filter_non_belongs_to_associations(data)
        data[:associations].reject { |a| a[:kind] == 'belongs_to' }
      end
    end
  end
end
