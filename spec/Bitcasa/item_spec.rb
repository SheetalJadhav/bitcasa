# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'item'

describe Bitcasa::Item do

  # TODO: auto-generated
  describe '#new' do
    it 'works' do
      client = double('client')
      parent:nil = double('parent:nil')
      in_trash:false = double('in_trash:false')
      **params = double('**params')
      result = Bitcasa::Item.new(client, parent:nil, in_trash:false, **params)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#url' do
    it 'works' do
      client = double('client')
      parent:nil = double('parent:nil')
      in_trash:false = double('in_trash:false')
      **params = double('**params')
      item = Bitcasa::Item.new(client, parent:nil, in_trash:false, **params)
      result = item.url
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#move_to' do
    it 'works' do
      client = double('client')
      parent:nil = double('parent:nil')
      in_trash:false = double('in_trash:false')
      **params = double('**params')
      item = Bitcasa::Item.new(client, parent:nil, in_trash:false, **params)
      destination = double('destination')
      name:nil = double('name:nil')
      exists:'RENAME' = double('exists:'RENAME'')
      result = item.move_to(destination, name:nil, exists:'RENAME')
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#copy_to' do
    it 'works' do
      client = double('client')
      parent:nil = double('parent:nil')
      in_trash:false = double('in_trash:false')
      **params = double('**params')
      item = Bitcasa::Item.new(client, parent:nil, in_trash:false, **params)
      destination = double('destination')
      name:nil = double('name:nil')
      exists:'RENAME' = double('exists:'RENAME'')
      result = item.copy_to(destination, name:nil, exists:'RENAME')
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#delete' do
    it 'works' do
      client = double('client')
      parent:nil = double('parent:nil')
      in_trash:false = double('in_trash:false')
      **params = double('**params')
      item = Bitcasa::Item.new(client, parent:nil, in_trash:false, **params)
      force:false = double('force:false')
      commit:false = double('commit:false')
      result = item.delete(force:false, commit:false)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#restore' do
    it 'works' do
      client = double('client')
      parent:nil = double('parent:nil')
      in_trash:false = double('in_trash:false')
      **params = double('**params')
      item = Bitcasa::Item.new(client, parent:nil, in_trash:false, **params)
      destination:nil = double('destination:nil')
      exists:'FAIL' = double('exists:'FAIL'')
      result = item.restore(destination:nil, exists:'FAIL')
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#versions' do
    it 'works' do
      client = double('client')
      parent:nil = double('parent:nil')
      in_trash:false = double('in_trash:false')
      **params = double('**params')
      item = Bitcasa::Item.new(client, parent:nil, in_trash:false, **params)
      result = item.versions
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#save' do
    it 'works' do
      client = double('client')
      parent:nil = double('parent:nil')
      in_trash:false = double('in_trash:false')
      **params = double('**params')
      item = Bitcasa::Item.new(client, parent:nil, in_trash:false, **params)
      version_conflict:'FAIL' = double('version_conflict:'FAIL'')
      result = item.save(version_conflict:'FAIL')
      expect(result).not_to be_nil
    end
  end

end
