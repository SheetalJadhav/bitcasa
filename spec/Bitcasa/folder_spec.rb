# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'folder'

describe Bitcasa::Folder do

  # TODO: auto-generated
  describe '#upload' do
    it 'works' do
      folder = Bitcasa::Folder.new
      filepath = double('filepath')
      name:nil = double('name:nil')
      exists:'FAIL' = double('exists:'FAIL'')
      result = folder.upload(filepath, name:nil, exists:'FAIL')
      expect(result).not_to be_nil
    end
  end

end
