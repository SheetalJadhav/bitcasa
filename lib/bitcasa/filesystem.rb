require_relative 'client'
require_relative 'folder'
require_relative 'filesystem_common'

module Bitcasa
	# FileSystem class provides interface to maintain bitcasa user's filesystem
	class FileSystem
		attr_reader :client, :root
		
		# Initalizes instance of Bitcasa::FileSystem
		# @param client [Client] bitcasa restful api object
		# @raise Client::Errors::ArgumentError
		def initialize(client)
			raise Client::Errors::ArgumentError, 
				"invalid client, input type must be Client" unless client.is_a?(Client)
				@client = client
		end

		def root
			get_root unless @root
			@root
		end

		# Get root object of filesystem
		# @return [Folder] represents root folder of filesystem
		# @raise Client::Errors::ServiceError
		def get_root
			response = @client.get_folder_meta("/")
			@root = FileSystemCommon.create_item_from_hash(@client, **response)
			@root	
		end

		# List contents of an item if it's a Folder object or folder's absolute path
		# @param item [Folder|String] represent folder to list in end-user's filesystem
		# @return array of items under folder path, objects in array can be File, Folder, Share objects
		# @raise Client::Errors::ServiceError, Client::Errors::ArgumentError, NoMethodError
		def list(item: nil)
			
			if (Client::Utils.is_blank?(item) || item.is_a?(String))
				response = @client.list_folder(path: item, depth: 1)
				FileSystemCommon.create_items_from_hash_array(response, 
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
		# @raise Client::Errors::ServiceError, Client::Errors::ArgumentError
		def move(items, destination, exists: 'RENAME')
			raise Client::Errors::ArgumentError, 
				"Invalid input, expected items" unless items

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
		# @raise Client::Errors::ServiceError, Client::Errors::ArgumentError
		def copy(items, destination, exists: 'RENAME')
			raise Client::Errors::ArgumentError, 
				"Invalid input, expected items" unless items
			
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
		# @raise Client::Errors::ServiceError, Client::Errors::ArgumentError
		def delete(items, force: true, commit: false)
			raise Client::Errors::ArgumentError, 
				"Invalid input, blank or empty, expected items" unless items

			responses = []
			Array(items).each do |item|
				responses << item.delete(force: force, commit: commit)
			end
			responses
		end

		#	Restore an item from trash
		# @param item [File|Folder|String] item
		# @param destination_url [String] rescue or recreate(default root) path depending on exists option
		# @param exists ["FAIL"|"RESCUE"] action to take if the recovery operation encounters issues, default 'FAIL'
		# @return [File|Folder] item object
		# @raise Client::Errors::ServiceError, Client::Errors::ArgumentError
		def restore_item(item, destination_url, exists)
			if item.is_a?(String)
				response = @client.browse_trash(path: item)
				properties = response.fetch(:meta)
				item = FileSystemCommon.create_item_from_hash(@client, 
					in_trash: true, **properties)
			end
			
			item.restore(destination: destination_url, 
					exists: exists, raise_exception: true)
			item
		end

		#	Restore items from trash
		# @param items [File|Folder|String] array of items
		# @option destination [Folder|String] rescue (default root) or recreate(named path) path depending on exists option to place item into if the original path does not exist
		# @option exists ["FAIL"|"RESCUE"|"RECREATE"] action to take if the recovery operation encounters issues, default 'FAIL'
		# @return array of restored items
		# @raise Client::Errors::ServiceError, Client::Errors::ArgumentError
		def restore(items, destination: nil, exists: 'FAIL')
			raise Client::Errors::ArgumentError, 
				"Invalid input, expected items" unless items

			FileSystemCommon.validate_item_state(destination)
			destination_url = FileSystemCommon.get_folder_url(destination)

			response = []
			Array(items).each do |item|
				response << restore_item(item, destination_url, exists)
			end
			response
		end
		
		# Browse trash
	 	# @return array of items in trash
		# @raise Client::Errors::ServiceError
		def browse_trash
			response = @client.browse_trash
			FileSystemCommon.create_items_from_hash_array(response.fetch(:items), 
					@client, in_trash: true)
		end
	
		# List versions of file
		# @param item [File|String] file
		# @return array of items
		# @raise Client::Errors::ServiceError, Client::Errors::ArgumentError
		def list_file_versions(item)
			raise Client::Errors::ArgumentError, 
				"Invalid input, expected Item or string path" if Client::Utils.is_blank?(item)

			if item.is_a?(String)
				response = @client.list_file_versions(item)
				FileSystemCommon.create_items_from_hash_array(response, 
						@client, parent: item)
			else
				response = item.versions
			end
			response
		end

		# List user's shares
		# @return Share []
		# @raise Client::Errors::ServiceError
		def list_shares
			response = @client.list_shares
			FileSystemCommon.create_items_from_hash_array(response, @client)
		end

		# Create share of paths in user's filesystem
		# @param items [File|Folder|String []] each path in array represents file/folder
		# @return Share object
		# @raise Client::Errors::ServiceError, Client::Errors::ArgumentError
		def create_share(items)
			raise Client::Errors::ArgumentError, 
				"Invalid input, expected items or paths" if Client::Utils.is_blank?(items)

			paths = []	
			Array(items).each do |item|
				FileSystemCommon.validate_item_state(item)
				paths << FileSystemCommon.get_item_url(item)
			end

			response = @client.create_share(paths)
			FileSystemCommon.create_item_from_hash(@client, **response)
		end	

		private :restore_item
	end
end
