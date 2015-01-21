# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'file'

describe Bitcasa::File do

  # TODO: auto-generated
  describe '#new' do
    it 'works' do
      client = double('client')
      parent:nil = double('parent:nil')
      in_trash:false = double('in_trash:false')
      **params = double('**params')
      result = Bitcasa::File.new(client, parent:nil, in_trash:false, **params)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#download' do
    it 'works' do
      client = double('client')
      parent:nil = double('parent:nil')
      in_trash:false = double('in_trash:false')
      **params = double('**params')
      file = Bitcasa::File.new(client, parent:nil, in_trash:false, **params)
      local_path = double('local_path')
      filename:nil = double('filename:nil')
      result = file.download(local_path, filename:nil)
      expect(result).not_to be_nil
    end
  end

end
