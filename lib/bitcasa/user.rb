require_relative 'client'

module Bitcasa
	# User class maintains user profile information
	#
	# @author Mrinal Dhillon
	class User
		# @return [String] end user's username
		attr_reader :username
		
		# @return [Fixnum] creation time in milliseconds since epoch.
		attr_reader :created_at
		
		# @return [String] first name of user
		attr_reader :first_name
		
		# @return [String] last name of user
		attr_reader :last_name

		# @return [String] account id
		attr_reader :account_id
		
		# @return [String] locale
		attr_reader :locale
		
		# @return [Hash] user account state
		attr_reader :account_state
		
		# @return [Hash] storage details
		attr_reader :storage
		
		# @return [Hash] account plan
		attr_reader :account_plan

		# @return [String] eamil id of user
		attr_reader :email

		# @return [Hash] session details
		attr_reader :session
		
		# @return [Fixnum] last login time in milliseconds since epoch
		attr_reader :last_login
		
		# @return [Fixnum] internal id of user
		attr_reader :id
		
		# @param client [Client] bitcasa restful api object
		# @param [Hash] properties metadata of user
		# @option [String] :username
		# @option [Fixnum] :created_at in milliseconds since epoch
		# @option [String] :first_name
		# @option [String] :last_name
		# @option [String] :account_id
		# @option [String] :local
		# @option [String] :account_state
		# @option [String] :email
		# @option [Hash] :session
		# @option [Fixnum] :last_login in milliseconds since epoch
		# @option [String] :id
		def initialize(client, **properties)
			fail Client::Errors::ArgumentError, 
				"invalid client type #{client.class}, expected Bitcasa::Client" unless client.is_a?(Bitcasa::Client)

			@client = client
			set_user_info(**properties)
		end

		# @see #initialize
		# @review required parameters
		def set_user_info(**params)
			@username = params.fetch(:username) { fail Client::Errors::ArgumentError, 
				"Missing required username" }
			@created_at = params[:created_at]
			@first_name = params[:first_name]
			@last_name = params[:last_name]
			@account_id = params[:account_id]
			@locale = params[:locale]
			@account_state = params[:account_state]
			@storage = params[:storage]
			@account_plan = params[:account_plan]
			@email = params[:email]
			@session = params[:session]
			@last_login = params[:last_login]
			@id = params[:id]
			nil
		end

		# Get current storage used by this user
		# @return [Fixnum] usage in bytes
		def get_usage
			@storage.fetch(:usage).to_i
		end
	
		# Get storage limit of this user
		# @return [Fixnum] limit in bytes
		def get_quota
			@storage.fetch(:limit).to_i
		end
		
		# Get this user's plan
		# @return [String] plan	
		def get_plan
			@account_plan.map{|k, v| "#{k}['#{v}']"}.join(' ')
		end

		# Refresh this user's metadata from server
		def refresh
			response = @client.get_profile
			set_user_info(**response)
		end

		private :set_user_info
	end
end
