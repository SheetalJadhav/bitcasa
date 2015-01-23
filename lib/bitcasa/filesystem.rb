require_relative './client.rb'
require_relative './filesystem_common.rb'
require_relative './folder.rb'

module Bitcasa
	# FileSystem class provides interface to maintain bitcasa user's filesystem
	class FileSystem
		attr_reader :client, :root
		
		# Initalizes instance of Bitcasa::FileSystem
		# @param client [Bitcasa::Client] bitcasa restful api object
		# @raise Bitacasa:Client::InvalidArgumentError
		def initialize(client)
			raise Bitcasa::Client::InvalidArgumentError, 
				"invalid client, input type must be Bitcasa::Client" unless client.is_a?(Bitcasa::Client)
				@client = client
		end

		# Get root object of filesystem
		# @return [Folder] represents root folder of filesystem
		# @raise Bitcasa::Client::Error
		def get_root
			response = @client.get_folder_meta("/")
			@root = FileSystemCommon::create_item_from_hash(@client, **response)
			@root	
		end

		# List contents of an item if it's a Folder object or folder's absolute path
		# @param item [Folder|String] represent folder to list in end-user's filesystem
		# @return array of items under folder path, objects in array can be File, Folder, Share objects
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError, NoMethodError
		def list(item: nil)
			
			if (Utils::is_blank?(item) || item.is_a?(String))
				response = @client.list_folder(path: item, depth: 1)
				FileSystemCommon::create_items_from_hash_array(response, 
						@client, parent: item)
			else
				item.list
			end
		end

		#	Move items to destination
		# @param items [File|Folder] array of items
		# @param destination [Folder|String] destination folder to move items to
		# @option exists ["FAIL"|"OVERWRITE"|"RENAME"] action to take in case of a conflict with an existing item in destination folder, default "RENAME"
		# @return array of moved items
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def move(items, destination, exists: 'RENAME')
			raise Bitcasa::Client::InvalidArgumentError, 
				"Invalid input, expected items" if Utils::is_blank?(items)

			response = []
			Array(items).each do |item|
				response << item.move_to(destination, exists: exists)
			end
			response
		end

		#	Copy items to destination
		# @param items [File|Folder] array of items
		# @param destination [Folder|String] destination folder to copy items to
		# @option exists ["FAIL"|"OVERWRITE"|"RENAME"] action to take in case of a conflict with an existing item in destination folder, default "RENAME"
		# @return array of copied items
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def copy(items, destination, exists: 'RENAME')
			raise Bitcasa::Client::InvalidArgumentError, 
				"Invalid input, expected items" if Utils::is_blank?(items)
			
			response = []
			Array(items).each do |item|
				response << item.copy_to(destination, exists: exists)
			end
			response
		end

		#	Delete items
		# @param items [File|Folder] array of items
		# @option commit [boolean] default false, set true to remove files/folders permanently, else will be moved to trash  
		# @option force [boolean] default false, set true to delete non-empty folders 
		# @return array of responses i.e. true/false
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def delete(items, force: false, commit: false)
			raise Bitcasa::Client::InvalidArgumentError, 
				"Invalid input, blank or empty, expected items" if Utils::is_blank?(items)

			responses = []
			Array(items).each do |item|
				responses << item.delete(force: force, commit: commit)
			end
			responses
		end

		#	Restore an item from trash
		# @param item_url [String] path of item
		# @param destination_url [String] rescue or recreate(default root) path depending on exists option
		# @param exists ["FAIL"|"RESCUE"|"RECREATE"] action to take if the recovery operation encounters issues, default 'FAIL'
		# @return [Boolean] response i.e. true/false
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def restore_item(item_url, destination_url, exists)
			@client.recover_trash_item(item_url, destination: destination_url, 
					restore: exists)
			true
			rescue Bitcasa::Client::Error
				false
		end 

		#	Restore items from trash
		# @param items [File|Folder|String] array of items
		# @option destination [Folder|String] rescue or recreate(default root) path depending on exists option
		# @option exists ["FAIL"|"RESCUE"|"RECREATE"] action to take if the recovery operation encounters issues, default 'FAIL'
		# @return array of responses i.e. true/false
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		# TODO: update restored items properties,
		#				return updated items
		def restore(items, destination: nil, exists: 'FAIL')
			raise Bitcasa::Client::InvalidArgumentError, 
				"Invalid input, expected items" if Utils::is_blank?(items)
			destination_url = FileSystemCommon::get_folder_url(destination)

			response = []
			Array(items).each do |item|
				if item.is_a?(String)
					response << restore_item(item, destination_url, exists)
				else 
					response << item.restore(destination: destination, exists: exists)
				end
			end
			response
		end
		
		# Browse trash
	 	# @return array of items in trash
		# @raise Bitcasa::Client::Error
		def browse_trash
			response = @client.browse_trash
			FileSystemCommon::create_items_from_hash_array(response, 
					@client, in_trash: true)
		end
	
		# List versions of file
		# @param item [File|String] file
		# @return array of items
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def list_file_versions(item)
			raise Bitcasa::Client::InvalidArgumentError, 
				"Invalid input, expected Item or string path" if Utils::is_blank?(item)

			if item.is_a?(String)
				response = @client.list_file_versions(item)
				FileSystemCommon::create_items_from_hash_array(response, 
						@client, parent: item)
			else
				response = item.versions
			end
			response
		end

		# List user's shares
		# @return Share []
		# @raise Bitcasa::Client::Error
		def list_shares
			response = @client.list_shares
			FileSystemCommon::create_items_from_hash_array(response, @client)
		end

		# Create share of paths in user's filesystem
		# @param items [File|Folder|String []] each path in array represents file/folder
		# @return Share object
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def create_share(items)
			raise Bitcasa::Client::InvalidArgumentError, 
				"Invalid input, expected items or paths" if Utils::is_blank?(items)

			paths = []	
			Array(items).each do |item|
				paths << FileSystemCommon::get_item_url(item)
			end

			response = @client.create_share(paths)
			FileSystemCommon::create_item_from_hash(@client, **response)
		end	

		private :restore_item
	end
end
