# frozen_string_literal: true

module ActiveAdmin
  module Exportable
    class Exporter
      # TODO: extract this to other gem.
      def initialize(record, includes: [], remove_ids: false)
        unless record.is_a?(ActiveRecord::Relation) || record.is_a?(ActiveRecord::Base)
          raise ArgumentError, 'You need provide an ActiveRecord record as argument.'
        end

        @root = RootStruct.new(node: record, includes: includes, remove_ids: remove_ids)
      end

      def export
        @root.data
      end

      def to_file(path:)
        File.open(path, 'w') { |f| f.write to_json }
      end

      def to_json(*_args)
        export.to_json
      end

      class RootStruct
        def initialize(node:, remove_ids:, includes: [])
          @node = node
          @includes = includes
          @remove_ids = remove_ids
        end

        def data
          if @node.respond_to?(:size)
            @node.map do |n|
              generate_data(node: n, includes: @includes)
            end
          else
            generate_data(node: @node, includes: @includes)
          end
        end

        private

        def generate_data(node:, includes:)
          attributes = node.attributes
          a_data = associations_data(node: node, includes: includes)

          if @remove_ids
            attributes.delete('id')
            a_data.map do |a|
              [a[:foreign_type], a[:foreign_key]] if a[:kind] == 'belongs_to'
            end.flatten.compact.each do |key|
              attributes.delete(key)
            end
          end

          {
            class_name: node.class.name,
            attributes: attributes,
            associations: a_data
          }
        end

        def associations_data(node:, includes:)
          association_data = generate_association_data(node: node, includes: includes)
          return [association_data.data] if association_data.instance_of?(AssociationStruct)

          association_data.flatten.map(&:data)
        end

        def generate_association_data(node:, includes:)
          return [] if includes.nil? || includes.empty?

          case includes
          when Hash
            generate_association_data_for_hash(node: node, includes: includes)
          when Array
            generate_association_data_for_array(node: node, includes: includes)
          when Symbol
            generate_association_data_for_symbol(node: node, includes: includes)
          end
        end

        def generate_association_data_for_hash(node:, includes:)
          includes.map do |association_name, inner_includes|
            AssociationStruct.new(record: node, association_name: association_name, remove_ids: @remove_ids,
                                  next_level_includes: inner_includes)
          end
        end

        def generate_association_data_for_array(node:, includes:)
          includes.map do |association_name|
            # It needs to "pass" again because we don't know the element's kinds.
            generate_association_data(node: node, includes: association_name)
          end
        end

        def generate_association_data_for_symbol(node:, includes:)
          if node.respond_to?(:size)
            node.map do |inner_node|
              AssociationStruct.new(record: inner_node, association_name: includes, remove_ids: @remove_ids)
            end
          else
            AssociationStruct.new(record: node, association_name: includes, remove_ids: @remove_ids)
          end
        end
      end

      class AssociationStruct
        def initialize(record:, association_name:, remove_ids:, next_level_includes: nil)
          @next_level_includes = next_level_includes
          @reflection = record.association(association_name).reflection
          @association = record.send(association_name)
          @remove_ids = remove_ids
        end

        def data
          {
            name: @reflection.name,
            inverse: @reflection.inverse_of&.name,
            foreign_key: @reflection.foreign_key,
            foreign_type: @reflection.foreign_type,
            kind: @reflection.class.name.match(/.*::(?<shortname>\w+)Reflection/)['shortname'].underscore,
            content: RootStruct.new(node: @association, includes: @next_level_includes, remove_ids: @remove_ids).data
          }.compact
        end
      end
    end
  end
end
