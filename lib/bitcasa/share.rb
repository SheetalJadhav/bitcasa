module Bitcasa
	# Share class is used to create and manage shares	
	# TODO: unlock and get share from share key
	class Share
		attr_reader :share_key, :type, :name, :url, :short_url, 
			:size, :date_created, :password, :client
		attr_accessor :name

		# Intialize Share instance
		# @param client [Bitcasa::Client] bitcasa restful api object
		# @option share_key [String] id of the share
		# @option share_type [String]
		# @option share_name [String]
		# @option url [String]
		# @option short_url [String]
		# @option share_size [String]
		# @option date_created [Fixnum]
		def initialize(client, **params)
			raise Bitcasa::Client::InvalidArgumentError, 
				"invalid client, input type must be Bitcasa::Client" unless client.is_a?(Bitcasa::Client)
			@client = client
			set_share_info(**params)
		end

		def set_share_info(**params)
			raise Bitcasa::Client::InvalidArgumentError, 
				"missing parameter, share_key must be defined" if Utils::is_blank?(params[:share_key])

			@share_key = params[:share_key]
			@type = params[:share_type]
			@name = params[:share_name]
			@url = params[:url]
			@short_url = params[:short_url]
			@size = params[:share_size]
			@date_created = params[:date_created]
		end

		# List items in this share
		# @return array containing list of items
		# @raise Bitcasa::Client::Error
		def list
			response = @client.browse_share(@share_key)
			FileSystemCommon::create_items_from_hash_array(response, @client, in_share: true)
		end

		# Delete this share
		# @raise Bitcasa::Client::Error
		def delete
			@client.delete_share(@share_key)
			nil
		end
	
		# Change password of this share
		# @param password	[String] new password for this share
		# @option current_password [String] is required if password is already set for this share
		# @raise Bitcasa::Client::Error
		def set_password(password, current_password: nil)
			response = @client.alter_share_info(@share_key, 
					current_passowd: current_password, password: password)
			set_share_info(**response)
			nil
		end

		# Save current state of this share
		#		Only name, password can be saved for share
		# @option password [String] new password for this share
		# @raise Bitcasa::Client::Error
		def save(password: nil)
			response = @client.alter_share_info(@share_key, 
					current_password: password, name: @name)
			set_share_info(**response)
			nil
		end

		# Receive contents of this share at specified path in user's filesystem
		# @option path [String] path in user's account to receive share at, default is "/" root
		# @option exists ["RENAME"|"FAIL"|"OVERWRITE"] action to take in case of conflict with existing items at path
		# @return array of items
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def receive(path: nil, exists: 'RENAME')
			response = @client.receive_share(@share_key, 
					path: path, exists: exists)
			FileSystemCommon::create_items_from_hash_array(response, @client)
		end
		private :set_share_info
	end	
end
