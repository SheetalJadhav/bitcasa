# -*- encoding: utf-8 -*-

require './spec_helper'
require './factories'
require_relative '../../lib/Bitcasa'
require_relative '../../lib/Bitcasa/session'

describe Bitcasa::Session do
 
  # TODO: auto-generated
  describe '#new' do
    it 'Should give new session' do
      result = FactoryGirl.build(clientid, secret, host)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#authenticate' do
    it 'works' do
      clientid = "IT-WwqfXz-16tFQf7TKr5_eMJspiEGMuPpESMnay3nI"
      secret = "8CcbXGivxz351qmy7PDPbjcIMbF5w7EDuHzbV9lYO3xTB9HrR1yNK_SV7qdhOMBHpzi8ZYKL5gsa8ildS4ehYQ"
      host = "https://jsf36yfysd.cloudfs.io"
      session = Bitcasa::Session.new(clientid, secret, host)
      username = "sheetal.jadahv@izeltech.com"
      password = "Dh@nanjay786"
      result = session.authenticate(username, password)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#is_linked' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      session = Bitcasa::Session.new(clientid, secret, host)
      result = session.is_linked
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#unlink' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      session = Bitcasa::Session.new(clientid, secret, host)
      result = session.unlink
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#get_user' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      session = Bitcasa::Session.new(clientid, secret, host)
      result = session.get_user
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#create_account' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      session = Bitcasa::Session.new(clientid, secret, host)
      username = double('username')
      password = double('password')
      email = double('email:nil')
      first_name = double('first_name:nil')
      last_name = double('last_name:nil')
      result = session.create_account(username, password, email:nil, first_name:nil, last_name:nil)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#get_account' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      session = Bitcasa::Session.new(clientid, secret, host)
      result = session.get_account
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#get_filesystem' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      session = Bitcasa::Session.new(clientid, secret, host)
      result = session.get_filesystem
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#action_history' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      session = Bitcasa::Session.new(clientid, secret, host)
      start = double('start:-10')
      stop = double('stop:0')
      result = session.action_history(start:-10, stop:0)
      expect(result).not_to be_nil
    end
  end

end
