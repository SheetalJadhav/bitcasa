require_relative 'client'
require_relative 'filesystem_common'

module Bitcasa
	# Share class is used to create and manage shares	
	# TODO: unlock and get share from share key
	class Share
		attr_reader :share_key, :type, :url, :short_url, 
			:size, :date_created, :client, :changed_properties
		attr_accessor :name

		# Intialize Share instance
		# @param client [Bitcasa::Client] bitcasa restful api object
		# @param share_key [String] id of the share
		# @option share_type [String]
		# @option share_name [String]
		# @option url [String]
		# @option short_url [String]
		# @option share_size [String]
		# @option date_created [Fixnum]
		def initialize(client, **params)
			raise Client::Errors::ArgumentError, 
				"invalid client, input type must be Bitcasa::Client" unless client.is_a?(Bitcasa::Client)
			@client = client
			set_share_info(**params)
		end

		def set_share_info(**params)
			raise Client::Errors::ArgumentError, 
				"missing parameter, share_key must be defined" if Client::Utils.is_blank?(params[:share_key])

			@share_key = params[:share_key]
			@type = params[:share_type]
			@name = params[:share_name]
			@url = params[:url]
			@short_url = params[:short_url]
			@size = params[:share_size]
			@date_created = params[:date_created]
			changed_properties_reset
		end

		def changed_properties_reset
			@changed_properties = {}
		end

		def name=(value)
			@name = value
			@changed_properties[:name] = value
		end

		# List items in this share
		# @return array containing list of items
		# @raise Client::Errors::ServiceError
		def list
			response = @client.browse_share(@share_key)
			FileSystemCommon.create_items_from_hash_array(response, @client, in_share: true)
		end

		# Delete this share
		# @raise Client::Errors::ServiceError
		def delete
			@client.delete_share(@share_key)
			nil
		end
	
		# Change password of this share
		# @param password	[String] new password for this share
		# @option current_password [String] is required if password is already set for this share
		# @raise Client::Errors::ServiceError
		def set_password(password, current_password: nil)
			response = @client.alter_share_info(@share_key, 
					current_passowd: current_password, password: password)
			set_share_info(**response)
			nil
		end

		# Save current state of this share
		#		Only name, can be saved for share
		# @option password [String] Current password for this share
		# @raise Client::Errors::ServiceError
		def save(password: nil)
			if @changed_properties[:name]
				response = @client.alter_share_info(@share_key, 
					current_password: password, name: @changed_properties[:name])
				set_share_info(**response)
			end
			nil
		end

		# Receive contents of this share at specified path in user's filesystem
		# @option path [String] path in user's account to receive share at, default is "/" root
		# @option exists ["RENAME"|"FAIL"|"OVERWRITE"] action to take in case of conflict with existing items at path
		# @return array of items
		# @raise Client::Errors::ServiceError, Client::Errors::ArgumentError
		def receive(path: nil, exists: 'RENAME')
			response = @client.receive_share(@share_key, 
					path: path, exists: exists)
			FileSystemCommon.create_items_from_hash_array(response, @client)
		end
		private :set_share_info
	end	
end
