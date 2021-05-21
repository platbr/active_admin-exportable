# frozen_string_literal: true

module ActiveAdmin
  module Exportable
    class Engine < Rails::Engine
      initializer 'active_admin' do |_app|
        ActiveAdmin.before_load do |app|
          app.load_paths << File.expand_path('../../../app/admin', __dir__)
        end
      end
    end
  end
end
