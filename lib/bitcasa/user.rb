require_relative 'client'

# Bitcasa module which maintains User class for profile information
module Bitcasa
	# User class maintains user profile information
	class User

		attr_reader :username, :created_at, :first_name, :last_name, 
			:account_id, :locale, :account_state, :storage, :account_plan, 
			:email, :session, :last_login, :id
		attr_reader :client		
		
		# Initialize User object
		# @param client [Bitcasa::Client] bitcasa restful api object
		# @option params [Hash|keyword args]
		def initialize(client, **params)
			raise Client::Errors::ArgumentError, 
				"invalid client, input type must be Bitcasa::Client" unless client.is_a?(Bitcasa::Client)
			@client = client
						
			@username = params[:username]
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
		end

		# Get current storage used by this user
		# @return Fixnum usage in bytes
		def get_usage
			@storage.fetch(:usage).to_i
		end
	
		# Get storage limit of this user
		# @return Fixnum limit in bytes
		def get_quota
			@storage.fetch(:limit).to_i
		end
		
		# Get this user's plan
		# @return [String] plan	
		def get_plan
			@account_plan.map{|k, v| "#{k}['#{v}']"}.join(' ')
		end

	end
end
