# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'container'

describe Bitcasa::Container do

  # TODO: auto-generated
  describe '#list' do
    it 'works' do
      container = Bitcasa::Container.new
      result = container.list
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#create_folder' do
    it 'works' do
      container = Bitcasa::Container.new
      item = double('item')
      exists:'FAIL' = double('exists:'FAIL'')
      result = container.create_folder(item, exists:'FAIL')
      expect(result).not_to be_nil
    end
  end

end
