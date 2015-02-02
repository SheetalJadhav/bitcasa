require_relative 'client'
require_relative 'filesystem_common'

module Bitcasa
	# Share class is used to create and manage share	
	# 
	# @author Mrinal Dhillon
	# @todo unlock and get share from share key for another user
	class Share
		
		# @return [String] share_key
		attr_reader :share_key
		
		# @return [String] type
		attr_reader :type
		
		# @return [String] url
		attr_reader :url
		
		# @return [String] short_url
		attr_reader :short_url
		
		# @return [String] size
		attr_reader :size
		
		# @return [Timestamp] date_created in seconds since epoch
		attr_reader :date_created		
		
		# name of share	
		# @overload name
		# 	@return [String] name of share
		# @overload name=(value)
		# 	@param value [String]
		# 	@raise [Client::Errors::ServiceError, 
		#			Client::Errors::InvalidShareError]
		attr_accessor :name

		# @param client [Client] bitcasa restful api object
		# @param [Hash] properties metadata of share
		# @option  properties [String] :share_key
		# @option properties [String] :share_type
		# @option properties [String] :share_name
		# @option properties [String] :url
		# @option properties [String] :short_url
		# @option properties [String] :share_size
		# @option properties [Fixnum] :date_created
		def initialize(client, **properties)
			fail Client::Errors::ArgumentError, 
				"Invalid client, input type must be Bitcasa::Client" unless client.is_a?(Bitcasa::Client)
			@client = client
			set_share_info(**properties)
		end

		# @see #initialize
		def set_share_info(**params)
			@share_key = params.fetch(:share_key) { fail Client::Errors::ArgumentError, 
				"missing parameter, share_key must be defined" }
			@type = params[:share_type]
			@name = params[:share_name]
			@url = params[:url]
			@short_url = params[:short_url]
			@size = params[:share_size]
			@date_created = params[:date_created]
			@exists = true
			changed_properties_reset
			nil
		end

		# Reset changed properties
		def changed_properties_reset
			@changed_properties = {}
			nil
		end
	
		#	@return [Boolean] whether the share exists, 
		#		false only if it has been deleted
		def exists?
			@exists
		end

		# @see #name
		def name=(value)
			FileSystemCommon.validate_share_state(self)
			@name = value
			@changed_properties[:name] = value
			nil
		end

		# List items in this share
		# @return [Array<File, Folder>] list of items
		# @raise [Client::Errors::ServiceError, 
		#		Client::Errors::InvalidShareError]
		def list
			FileSystemCommon.validate_share_state(self)
			response = @client.browse_share(@share_key)
			FileSystemCommon.create_items_from_hash_array(response, @client, in_share: true)
		end

		# Delete this share
		# @note Subsequent operations shall raise Client::Errors::InvalidShareError
		# @raise [Client::Errors::ServiceError, 
		#		Client::Errors::InvalidShareError]
		def delete
			FileSystemCommon.validate_share_state(self)
			@client.delete_share(@share_key)
			@exists = false
			nil
		end
	
		# Change password of this share
		# @param password	[String] new password for this share
		# @param current_password [String] is required if password is already set for this share
		# @return [nil]
		# @raise [Client::Errors::ServiceError, 
		#		Client::Errors::InvalidShareError]
		def set_password(password, current_password: nil)
			FileSystemCommon.validate_share_state(self)
			response = @client.alter_share_info(@share_key, 
					current_passowd: current_password, password: password)
			set_share_info(**response)
			nil
		end

		# Save current state of this share
		#		Only name, can be saved for share
		# @param password [String] Current password for this share
		# @return [nil]
		# @raise [Client::Errors::ServiceError, 
		#		Client::Errors::InvalidShareError]
		def save(password: nil)
			FileSystemCommon.validate_share_state(self)
			if @changed_properties[:name]
				response = @client.alter_share_info(@share_key, 
					current_password: password, name: @changed_properties[:name])
				changed_properties_reset
			end
			nil
		end

		# Receive contents of this share at specified path in user's filesystem
		# @param path [String] path in user's account to receive share at, default is "/" root
		# @param exists [String] ('RENAME', 'FAIL', 'OVERWRITE') action to take in 
		#		case of conflict with existing items at path
		# @return [Array<File, Folder>] items
		# @raise [Client::Errors::ServiceError, 
		#		Client::Errors::InvalidShareError]
		def receive(path: nil, exists: 'RENAME')
			response = @client.receive_share(@share_key, 
					path: path, exists: exists)
			FileSystemCommon.create_items_from_hash_array(response, @client)
		end

		private :set_share_info, :changed_properties_reset
	end	
end
