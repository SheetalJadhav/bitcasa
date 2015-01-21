# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'filesystem'

describe Bitcasa::FileSystem do

  # TODO: auto-generated
  describe '#new' do
    it 'works' do
      client = double('client')
      result = Bitcasa::FileSystem.new(client)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#get_root' do
    it 'works' do
      client = double('client')
      file_system = Bitcasa::FileSystem.new(client)
      result = file_system.get_root
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#list' do
    it 'works' do
      client = double('client')
      file_system = Bitcasa::FileSystem.new(client)
      item:nil = double('item:nil')
      result = file_system.list(item:nil)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#move' do
    it 'works' do
      client = double('client')
      file_system = Bitcasa::FileSystem.new(client)
      items = double('items')
      destination = double('destination')
      exists:'RENAME' = double('exists:'RENAME'')
      result = file_system.move(items, destination, exists:'RENAME')
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#copy' do
    it 'works' do
      client = double('client')
      file_system = Bitcasa::FileSystem.new(client)
      items = double('items')
      destination = double('destination')
      exists:'RENAME' = double('exists:'RENAME'')
      result = file_system.copy(items, destination, exists:'RENAME')
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#delete' do
    it 'works' do
      client = double('client')
      file_system = Bitcasa::FileSystem.new(client)
      items = double('items')
      force:false = double('force:false')
      commit:false = double('commit:false')
      result = file_system.delete(items, force:false, commit:false)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#restore' do
    it 'works' do
      client = double('client')
      file_system = Bitcasa::FileSystem.new(client)
      items = double('items')
      destination:nil = double('destination:nil')
      exists:'FAIL' = double('exists:'FAIL'')
      result = file_system.restore(items, destination:nil, exists:'FAIL')
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#browse_trash' do
    it 'works' do
      client = double('client')
      file_system = Bitcasa::FileSystem.new(client)
      result = file_system.browse_trash
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#list_file_versions' do
    it 'works' do
      client = double('client')
      file_system = Bitcasa::FileSystem.new(client)
      item = double('item')
      result = file_system.list_file_versions(item)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#list_shares' do
    it 'works' do
      client = double('client')
      file_system = Bitcasa::FileSystem.new(client)
      result = file_system.list_shares
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#create_share' do
    it 'works' do
      client = double('client')
      file_system = Bitcasa::FileSystem.new(client)
      items = double('items')
      result = file_system.create_share(items)
      expect(result).not_to be_nil
    end
  end

end
