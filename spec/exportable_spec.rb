# frozen_string_literal: true

require 'spec_helper'

describe ActiveAdmin::Exportable do
  describe 'extends ResourceDSL' do
    it 'by adding #exportable' do
      dsl = ActiveAdmin::ResourceDSL

      expect(dsl.public_instance_methods).to include(:exportable)
    end
  end

  it 'enables form-based exportion by default' do
    dsl = ActiveAdmin::ResourceDSL.new(double('config'))

    expect(dsl).to receive(:enable_resource_exportion_via_form)

    dsl.exportable
  end

  it 'enables save-based exportion with option `via: :save`' do
    dsl = ActiveAdmin::ResourceDSL.new(double('config'))

    expect(dsl).to receive(:enable_resource_exportion_via_save)

    dsl.exportable(via: :save)
  end
end
