# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'share'

describe Bitcasa::Share do

  # TODO: auto-generated
  describe '#new' do
    it 'works' do
      client = double('client')
      **params = double('**params')
      result = Bitcasa::Share.new(client, **params)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#list' do
    it 'works' do
      client = double('client')
      **params = double('**params')
      share = Bitcasa::Share.new(client, **params)
      result = share.list
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#delete' do
    it 'works' do
      client = double('client')
      **params = double('**params')
      share = Bitcasa::Share.new(client, **params)
      result = share.delete
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#set_password' do
    it 'works' do
      client = double('client')
      **params = double('**params')
      share = Bitcasa::Share.new(client, **params)
      password = double('password')
      current_password:nil = double('current_password:nil')
      result = share.set_password(password, current_password:nil)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#save' do
    it 'works' do
      client = double('client')
      **params = double('**params')
      share = Bitcasa::Share.new(client, **params)
      password:nil = double('password:nil')
      result = share.save(password:nil)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#receive' do
    it 'works' do
      client = double('client')
      **params = double('**params')
      share = Bitcasa::Share.new(client, **params)
      path:nil = double('path:nil')
      exists:'RENAME' = double('exists:'RENAME'')
      result = share.receive(path:nil, exists:'RENAME')
      expect(result).not_to be_nil
    end
  end

end
