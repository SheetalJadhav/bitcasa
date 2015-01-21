# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'client/error'

describe Bitcasa::Client do

  # TODO: auto-generated
  describe '#raise_server_error' do
    it 'works' do
      error = double('error')
      result = Bitcasa::Client.raise_server_error(error)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#raise_error' do
    it 'works' do
      error = double('error')
      result = Bitcasa::Client.raise_error(error)
      expect(result).not_to be_nil
    end
  end

end
