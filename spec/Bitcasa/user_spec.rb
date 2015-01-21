# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'user'

describe Bitcasa::User do

  # TODO: auto-generated
  describe '#new' do
    it 'works' do
      client = double('client')
      **params = double('**params')
      result = Bitcasa::User.new(client, **params)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#get_usage' do
    it 'works' do
      client = double('client')
      **params = double('**params')
      user = Bitcasa::User.new(client, **params)
      result = user.get_usage
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#get_quota' do
    it 'works' do
      client = double('client')
      **params = double('**params')
      user = Bitcasa::User.new(client, **params)
      result = user.get_quota
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#get_plan' do
    it 'works' do
      client = double('client')
      **params = double('**params')
      user = Bitcasa::User.new(client, **params)
      result = user.get_plan
      expect(result).not_to be_nil
    end
  end

end
