# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'client/utils'

describe Bitcasa::Utils do

  # TODO: auto-generated
  describe '#urlencode' do
    it 'works' do
      value = double('value')
      result = Bitcasa::Utils.urlencode(value)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#hash_to_urlencoded_str' do
    it 'works' do
      hash = double('hash')
      delim = double('delim')
      join_with = double('join_with')
      result = Bitcasa::Utils.hash_to_urlencoded_str(hash, delim, join_with)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#generate_auth_signature' do
    it 'works' do
      endpoint = double('endpoint')
      params = double('params')
      headers = double('headers')
      secret = double('secret')
      result = Bitcasa::Utils.generate_auth_signature(endpoint, params, headers, secret)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#json_to_hash' do
    it 'works' do
      json_str = double('json_str')
      result = Bitcasa::Utils.json_to_hash(json_str)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#hash_to_json' do
    it 'works' do
      hash = double('hash')
      result = Bitcasa::Utils.hash_to_json(hash)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#hash_to_arguments' do
    it 'works' do
      hash = double('hash')
      *field = double('*field')
      result = Bitcasa::Utils.hash_to_arguments(hash, *field)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#is_blank?' do
    it 'works' do
      var = double('var')
      result = Bitcasa::Utils.is_blank?(var)
      expect(result).not_to be_nil
    end
  end

end
