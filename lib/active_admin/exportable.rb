# frozen_string_literal: true

require 'active_admin'
require 'active_admin/exportable/version'
require 'active_admin/exportable/engine'
require 'active_admin/exportable/exporter'
require 'active_admin/exportable/importer'

module ActiveAdmin
  module Exportable
    extend ActiveSupport::Concern

    def exportable(options = {})
      includes = options.fetch(:includes) { [] }
      remove_ids = options.fetch(:remove_ids, true)
      filename_method = options[:filename_method]
      format = options.fetch(:format, :json)
      enable_resource_exportion(includes: includes, remove_ids: remove_ids, filename_method: filename_method,
                                format: format)
    end

    private

    def enable_resource_exportion(includes:, remove_ids:, filename_method:, format:)
      action_item(*compatible_action_item_parameters) do
        if controller.action_methods.include?('new') && authorized?(ActiveAdmin::Auth::CREATE,
                                                                    active_admin_config.resource_class)
          link_to(
            I18n.t(
              :export_model,
              default: 'Export %{model}',
              scope: [:active_admin],
              model: active_admin_config.resource_label
            ),
            { action: :export }
          )
        end
      end

      member_action :export do
        resource = resource_class.find(params[:id])

        authorize! ActiveAdmin::Auth::CREATE, resource

        exported = ActiveAdmin::Exportable::Exporter.new(resource, includes: includes,
                                                                   remove_ids: remove_ids).export.send("to_#{format}")
        filename = "#{resource.send(filename_method)}.#{format}" if filename_method.present?
        filename ||= "#{resource_class.name.downcase}_#{resource.id}.#{format}"

        send_data exported, type: "application/#{format}", filename: filename
      end
    end

    # For ActiveAdmin `action_item` compatibility.
    #
    # - When ActiveAdmin is less than 1.0.0.pre1 exclude name parameter from
    #   calls to `action_item` for compatibility.
    # - When 1.0.0.pre1 or greater provide name to `action_item` to avoid the
    #   warning message, and later an error.
    #
    # Returns Array of parameters.
    def compatible_action_item_parameters
      parameters = [{ only: %i[show edit] }]
      parameters.unshift(:exportable_export) if action_item_name_required?
      parameters
    end

    def action_item_name_required?
      method(:action_item).parameters.count == 3
    end
  end
end

ActiveAdmin::ResourceDSL.include ActiveAdmin::Exportable
