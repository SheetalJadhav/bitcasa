# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'filesystem_common'

describe Bitcasa::FileSystemCommon do

  # TODO: auto-generated
  describe '#create_item_from_hash' do
    it 'works' do
      client = double('client')
      parent:nil = double('parent:nil')
      in_trash:false = double('in_trash:false')
      **hash = double('**hash')
      result = Bitcasa::FileSystemCommon.create_item_from_hash(client, parent:nil, in_trash:false, **hash)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#create_items_from_hash_array' do
    it 'works' do
      hashes = double('hashes')
      client = double('client')
      parent:nil = double('parent:nil')
      in_trash:false = double('in_trash:false')
      result = Bitcasa::FileSystemCommon.create_items_from_hash_array(hashes, client, parent:nil, in_trash:false)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#get_folder_url' do
    it 'works' do
      folder = double('folder')
      result = Bitcasa::FileSystemCommon.get_folder_url(folder)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#get_item_url' do
    it 'works' do
      item = double('item')
      result = Bitcasa::FileSystemCommon.get_item_url(item)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#get_item_name' do
    it 'works' do
      item = double('item')
      result = Bitcasa::FileSystemCommon.get_item_name(item)
      expect(result).not_to be_nil
    end
  end

end
