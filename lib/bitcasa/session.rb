require_relative 'client'
require_relative 'account'
require_relative 'user'
require_relative 'filesystem'

module Bitcasa
	# Establishes a session with the api server on behalf of an authenticated end-user
	#		
	#	It maintains restful bitcasa api client object that provides authenticated access 
	#		to Bitcasa Cloudfs service end user's account and is shared will 
	#		filesystem objects linked with this session - Filesystem, Container, File, Folder, Share, Account, User
	#	@author Mrinal Dhillon
	#	@example
	#		session = Bitcasa::Session.new(clientid, secret, host)
	#		session.is_linked?		#=> false
	#		session.autheticate(username, password)
	#		session.is_linked?		#=> true
	#		folder = session.filesystem.root.create_folder("newfolder")
	#		folder.name = newname
	#		folder.save
	#		file = folder.upload(local_filepath)
	#		session.unlink
	class Session

		# Credentials of Paid Bitcasa User's admin account
		# @overload admin_credentials
		# 	@return [String] 
		# @overload admin_credentials=(creds={})
		#		@param [Hash] creds
		#		@option creds [String] :clientid admin account clientid
		#		@option creds [String] :secret admin account secret
		#		@option creds [String] :host (access.bitcasa.com) admin account host
		attr_accessor :admin_credentials

		# @return [FileSystem] filesystem linked with this session
		attr_reader :filesystem

		# @return [Account] current account
		# @raise [Client::Errors::ServiceError,
		#		Client::Errors::OperationNotAllowedError]
		attr_reader :account
		
		# @return [User] current user
		# @raise [Client::Errors::ServiceError, 
		#		Client::Errors::OperationNotAllowedError]
		attr_reader :user
		
		# @param clientid [String] account clientid
		# @param secret [String] account secret
		# @param host [String] bitcasa api server hostname
		def initialize(clientid, secret, host)
			@clientid = clientid
			@secret = secret
			@host = host
			@client = Client.new(clientid, secret, host)
			@unlinked = false
			@admin_credentials = {}
		end
	
		def admin_credentials=(creds={})
			@admin_credentials[:clientid] = "#{creds.fetch(:clientid, nil)}"
			@admin_credentials[:secret] = "#{creds.fetch(:secret, nil)}"
			@admin_credentials[:host] = "#{creds.fetch(:host, "access.bitcasa.com")}"
		end

		def admin_credentials
			@admin_credentials.map{|k, v| "#{k}['#{v}']"}.join(' ')
		end
		
		def filesystem
			@filesystem ||= FileSystem.new(@client) 
		end

		def user
			@user ||= get_user 
		end

		def account
			@account ||= get_account
		end

		# Attempts to log into the end-user's filesystem, links this session to an account
		#
		# @param username [String] end user's username
		# @param password [String] end user's password
		#
		# @return [true]
		# @raise [Client::Errors::ServiceError, Client::Errors::ArgumentError, 
		#		Client::Errors::OperationNotAllowedError]
		def authenticate(username, password)
			validate_session
			fail Client::Errors::OperationNotAllowedError, 
				"Cannot re-authenticate, initialize new session instance" if is_linked?
			
			@client.authenticate(username, password)
		end

		# Tests to see if the current session is linked to the API server 
		#		and can make requests	
		# @return [Boolean] true if session is authenticated
		def is_linked?
			@client.linked?
		end

		# Discards current authentication
		#
		# @note	Bitcasa objects remain valid only till session is linked, 
		#		once unlinked all restful objects generated through this session 
		#		are expected to raise SessionNotLinked exception for any restful operation.
		#	@note session cannot be re-authenticated once unlinked.
		#
		# @return [true]
		def unlink
			@client.unlink
			@unlinked = true
		end

		
		# Creates a new end-user account for a Paid CloudFS account
		#
		# @param username [String] username of the end-user, 
		#		must be at least 4 characters and less than 256 characters
		# @param password [String] password of the end-user, 
		#		must be at least 6 characters and has no length limit
		# @param email [String] email of the end-user
		# @param first_name [String] first name of end user
		# @param last_name [String] last name of end user
		# @return [Account] new user account
		#
		# @note Created Account is not linked, 
		#		authenticate this session with new account credentials before using it.
		#	@example
		#		Create session, create new account and link session
		#		session = Session.new(clientid, secret, host) # credentials of prototype account	
		#		session.admin_credentials={clientid: clientid, secret: secret} #  admin creds
		#		account = session.create_account(new_username, new_password)
		#		session.authenticate(new_username, new_password)
		# @raise [Client::Errors::ServiceError, Client::Errors::ArgumentError,
		#		Client::Errors::OperationNotAllowedError]
		# @review account creation can be made possible even if session has already been 
		#		linked or unlinked, but returning new Account with this session's restful client
		#		is not possible since session does not allow re-authentication if it
		#		has already been linked with another user.
		def create_account(username, password, email: nil, 
				first_name: nil, last_name: nil)
			validate_session
			fail Client::Errors::OperationNotAllowedError, 
				"New account creation with linked session is not possible, 
						initialize new session instance" if is_linked?

			admin_client = Client.new(@admin_credentials[:clientid], 
					@admin_credentials[:secret], @admin_credentials[:host])

			response = admin_client.create_account(username, password, email: email, 
				first_name: first_name, last_name: last_name)
			Account.new(@client, **response)
	
			ensure
				admin_client.unlink if (defined? admin_client) && admin_client.respond_to?(:unlink)
		end
		
		def get_account
			validate_session
			response = @client.get_profile
			Account.new(@client, **response)
		end

		def get_user
			validate_session
			response = @client.get_profile
			User.new(@client, **response)
		end

		# Action history lists history of file, folder, and share actions
		# @param start [Fixnum] version number to start listing historical actions from, 
		#		default -10. It can be negative in order to get most recent actions.
		# @param stop [Fixnum] version number to stop listing historical actions from (non-inclusive)
		# @return [Array<Hash>] history items
		# @raise [Client::Errors::ServiceError, Client::Errors::OperationNotAllowedError]
		def action_history(start: -10, stop: 0)
			validate_session
			@client.list_history
		end
		
		# @raise [Client::Errors::OperationNotAllowedError]
		def validate_session
			fail Client::Errors::OperationNotAllowedError,
				"This session has been unlinked, initialize new session instance" if @unlinked
		end
		private :validate_session, :get_user, :get_account
	end
end
