# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'client'

describe Bitcasa::Client do

  # TODO: auto-generated
  describe '#new' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      result = Bitcasa::Client.new(clientid, secret, host)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#is_linked' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      result = client.is_linked
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#unlink' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      result = client.unlink
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#authenticate' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      username = double('username')
      password = double('password')
      result = client.authenticate(username, password)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#ping' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      result = client.ping
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#create_account' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      username = double('username')
      password = double('password')
      email = double('email:nil')
      first_name = double('first_name:nil')
      last_name = double('last_name:nil')
      result = client.create_account(username, password, email:nil, first_name:nil, last_name:nil)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#get_profile' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      result = client.get_profile
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#create_folder' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path = double('path')
      name = double('name')
      exists = double('exists:'FAIL'')
      result = client.create_folder(path, name, exists:'FAIL')
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#list_folder' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path = double('path:"/"')
      depth = double('depth:0')
      filter = double('filter:nil')
      strict_traverse = double('strict_traverse:false')
      result = client.list_folder(path:"/", depth:0, filter:nil, strict_traverse:false)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#delete_folder' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path = double('path')
      commit = double('commit:false')
      force = double('force:false')
      result = client.delete_folder(path, commit:false, force:false)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#delete_file' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path = double('path')
      commit = double('commit:false')
      result = client.delete_file(path, commit:false)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#copy_folder' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path = double('path')
      destination = double('destination')
      name = double('name:""')
      exists = double('exists:'FAIL'')
      result = client.copy_folder(path, destination, name:"", exists:'FAIL')
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#copy_file' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path = double('path')
      destination = double('destination')
      name = double('name:""')
      exists = double('exists:'RENAME'')
      result = client.copy_file(path, destination, name:"", exists:'RENAME')
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#move_folder' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path = double('path')
      destination = double('destination')
      name = double('name')
      exists:'FAIL' = double('exists:'FAIL'')
      result = client.move_folder(path, destination, name, exists:'FAIL')
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#move_file' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path = double('path')
      destination = double('destination')
      name = double('name')
      exists:'RENAME' = double('exists:'RENAME'')
      result = client.move_file(path, destination, name, exists:'RENAME')
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#get_folder_meta' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path = double('path')
      result = client.get_folder_meta(path)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#get_file_meta' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path = double('path')
      result = client.get_file_meta(path)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#alter_folder_meta' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path = double('path')
      version = double('version')
      version_conflict:'FAIL' = double('version_conflict:'FAIL'')
      **properties = double('**properties')
      result = client.alter_folder_meta(path, version, version_conflict:'FAIL', **properties)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#alter_file_meta' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path = double('path')
      version = double('version')
      version_conflict:'FAIL' = double('version_conflict:'FAIL'')
      **properties = double('**properties')
      result = client.alter_file_meta(path, version, version_conflict:'FAIL', **properties)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#upload' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path = double('path')
      filepath = double('filepath')
      name:"" = double('name:""')
      exists:'FAIL' = double('exists:'FAIL'')
      result = client.upload(path, filepath, name:"", exists:'FAIL')
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#download' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path = double('path')
      startbyte:0 = double('startbyte:0')
      bytecount:0 = double('bytecount:0')
      &block = double('&block')
      result = client.download(path, startbyte:0, bytecount:0, &block)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#list_single_file_version' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path = double('path')
      version = double('version')
      result = client.list_single_file_version(path, version)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#promote_file_version' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path = double('path')
      version = double('version')
      result = client.promote_file_version(path, version)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#list_file_versions' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path = double('path')
      start_version:0 = double('start_version:0')
      stop_version:-1 = double('stop_version:-1')
      limit:10 = double('limit:10')
      result = client.list_file_versions(path, start_version:0, stop_version:-1, limit:10)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#create_share' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      paths = double('paths')
      result = client.create_share(paths)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#delete_share' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      share_key = double('share_key')
      result = client.delete_share(share_key)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#browse_share' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      share_key = double('share_key')
      path:"" = double('path:""')
      result = client.browse_share(share_key, path:"")
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#list_shares' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      result = client.list_shares
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#receive_share' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      share_key = double('share_key')
      path:"" = double('path:""')
      exists:'RENAME' = double('exists:'RENAME'')
      result = client.receive_share(share_key, path:"", exists:'RENAME')
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#unlock_share' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      share_key = double('share_key')
      password = double('password')
      result = client.unlock_share(share_key, password)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#alter_share_info' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      share_key = double('share_key')
      current_password:"" = double('current_password:""')
      password:"" = double('password:""')
      name:"" = double('name:""')
      result = client.alter_share_info(share_key, current_password:"", password:"", name:"")
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#list_history' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      start:-10 = double('start:-10')
      stop:0 = double('stop:0')
      result = client.list_history(start:-10, stop:0)
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#browse_trash' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path:"" = double('path:""')
      result = client.browse_trash(path:"")
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#delete_trash_item' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path:"" = double('path:""')
      result = client.delete_trash_item(path:"")
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#recover_trash_item' do
    it 'works' do
      clientid = double('clientid')
      secret = double('secret')
      host = double('host')
      client = Bitcasa::Client.new(clientid, secret, host)
      path = double('path')
      restore:'FAIL' = double('restore:'FAIL'')
      destination:nil = double('destination:nil')
      result = client.recover_trash_item(path, restore:'FAIL', destination:nil)
      expect(result).not_to be_nil
    end
  end

end
