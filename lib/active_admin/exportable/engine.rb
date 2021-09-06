# frozen_string_literal: true

module ActiveAdmin
  module Exportable
    class Engine < Rails::Engine
      initializer 'active_admin' do |_app|
        ActiveAdmin.before_load do |app|
          ActiveAdmin.register_page 'Import' do
            menu parent: 'Exportable'
            controller do
              private

              def import_options
                allow_update = ActiveModel::Type::Boolean.new.cast(params[:import][:allow_update])
                file_path = params[:import][:file]&.path
                format = params[:import][:format]
                raise 'Format is required.' if format.blank?
                raise 'File is required.' if file_path.blank?

                { path: file_path, format: format, allow_update: allow_update }
              end
            end

            content do
              columns do
                column do
                  div do
                    active_admin_form_for 'import', url: 'import/upload' do |f|
                      f.inputs name: 'Import', class: 'inputs' do
                        f.input :format, collection: %i[json yaml], input_html: { value: 'json' }
                        f.input :allow_update, as: :boolean
                        f.input :file, as: :file
                        f.action :submit
                      end
                    end
                  end
                end
              end
            end

            page_action :upload, method: :post do
              imported = ActiveAdmin::Exportable::Importer.new(**import_options)
              imported.import
              redirect_to admin_import_path, notice: 'Imported'
            rescue StandardError => e
              redirect_to admin_import_path, flash: { error: e.message }
            end
          end
        end
      end
    end
  end
end
