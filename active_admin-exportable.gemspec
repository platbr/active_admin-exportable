# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_admin/exportable/version'

Gem::Specification.new do |spec|
  spec.name          = 'active_admin-exportable'
  spec.version       = ActiveAdmin::Exportable::VERSION
  spec.authors       = ['Wagner Caixeta']
  spec.email         = ['wagner.caixeta@gmail.com.com']
  spec.summary       = 'A export/import tool for ActiveAdmin.'
  spec.description   = 'Allow user to export/import of ActiveRecord records and relations in ActiveAdmin.'
  spec.homepage      = 'https://github.com/zorab47/active_admin-exportable'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activeadmin'

  spec.add_development_dependency 'activerecord'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  # required for active admin
  spec.add_development_dependency 'sass-rails'
end
