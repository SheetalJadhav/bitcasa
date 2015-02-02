require_relative 'client'
require_relative 'folder'
require_relative 'filesystem_common'

module Bitcasa
	# FileSystem class provides interface to maintain bitcasa user's filesystem
	#
	# @author Mrinal Dhillon
	class FileSystem
		
		# @return [Folder] root folder of user's filesystem
		# @raise [Client::Errors::ServiceError]
		attr_reader :root
		
		# @param client [Client] bitcasa restful api object
		# @raise Client::Errors::ArgumentError
		def initialize(client)
			fail Client::Errors::ArgumentError, 
				"invalid client, input type must be Client" unless client.is_a?(Client)
				@client = client
		end

		# @return [Folder] root folder of user's filesystem
		# @raise [Client::Errors::ServiceError]
		def root
			@root ||= get_root
		end

		# Get root object of filesystem
		# @return [Folder] represents root folder of filesystem
		# @raise Client::Errors::ServiceError
		def get_root
				response = @client.get_folder_meta("/")
				FileSystemCommon.create_item_from_hash(@client, **response)
		end

		# List contents of an folder in user's filesystem
		#
		# @param item [Folder, String] folder object or url in end-user's filesystem
		#
		# @return [Array<Folder, File>] items under folder path
		# @raise [Client::Errors::ServiceError, Client::Errors::ArgumentError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
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
		#
		# @param items [Array<File, Folder>] items
		# @param destination [Folder, String] destination folder or url
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') action to take in case 
		#	of a conflict with an existing item in destination folder, default "RENAME"
		#
		# @return [Array<File, Folder>] moved items
		#	@note item at index in returned array is refrence to same object
		#		whose properties are updated as an effect of move operation at corresponding 
		#		index in input array 'items'
		# @raise [Client::Errors::ServiceError, Client::Errors::ArgumentError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
		# @see Item#move_to
		def move(items, destination, exists: 'RENAME')
			fail Client::Errors::ArgumentError, 
				"Invalid input, expected items" unless items

			response = []
			Array(items).each do |item|
				response << item.move_to(destination, exists: exists)
			end
			response
		end

		#	Copy items to destination
		#
		# @param items [Array<File, Folder>] items
		# @param destination [Folder, String] destination folder or url
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') action to take in case 
		#	of a conflict with an existing item in destination folder, default 'RENAME'
		#
		# @return [Array<File, Folder>] copied items
		# @raise [Client::Errors::ServiceError, Client::Errors::ArgumentError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
		#	@note item at index in returned array is refrence to same object
		#		at corresponding index in input array 'items'
		# @see Item#copy_to
		def copy(items, destination, exists: 'RENAME')
			fail Client::Errors::ArgumentError, 
				"Invalid input, expected array of items" unless items
			
			response = []
			Array(items).each do |item|
				response << item.copy_to(destination, exists: exists)
			end
			response
		end

		#	Delete items from user's filesystem
		#
		# @param items [Array<File, Folder>] items
		# @param force [Boolean] (false) set true to delete non-empty folder		
		# @param commit [Boolean] (false) set true to remove item permanently, 
		#		else deleted items are moved to trash
		#	
		# @return [Array<Boolean>]
		# @raise [Client::Errors::ServiceError, Client::Errors::ArgumentError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
		#
		#	@note item at index in returned array is refrence to same object
		#		whose properties are updated as an effect of delete operation at 
		#		corresponding index in input array 'items'
		# @see Item#delete Delete an item
		# @see #restore Restore items
		# @see Item#restore Restore an item
		def delete(items, force: false, commit: false)
			fail Client::Errors::ArgumentError, 
				"Invalid input, expected array of items" unless items

			responses = []
			Array(items).each do |item|
				responses << item.delete(force: force, commit: commit)
			end
			responses
		end

		#	Restore an item from trash
		#
		# @param item [File, Folder, String] item or url
		# @param destination_url [String] rescue or recreate(default root) 
		#		path depending on exists option
		# @param exists [String] ('FAIL', 'RESCUE', RECREATE) action to take 
		#		if the recovery operation encounters issues, default 'FAIL'
		#
		# @return [File, Folder] item object
		# @raise [Client::Errors::ServiceError, Client::Errors::ArgumentError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
		def restore_item(item, destination_url, exists)
			if item.is_a?(String)
				response = @client.browse_trash(path: item)
				properties = response.fetch(:meta)
				item = FileSystemCommon.create_item_from_hash(@client, 
					in_trash: true, **properties)
			end
			
			item.restore(destination: destination_url, 
					exists: exists, raise_exception: true)
		end

		#	Restore items from trash
		#
		# @param items [File, Folder, String] items
		# @param destination [Folder, String] ('RESCUE' (default root), 
		#		RECREATE(named path)) path depending on exists option to place item into 
		#		if the original path does not exist.
		# @param exists [String] ('FAIL', 'RESCUE', 'RECREATE') 
		#		action to take if the recovery operation encounters issues, default 'FAIL'
		# @return [Array<File, Folder>] restored items
		#	@note unless item is url at corresponding index in input array 'items', 
		#		the item at index in returned array is refrence to same object
		#		whose properties are updated as an effect of restore operation at 
		#		corresponding index in input array 'items'
		#
		# @raise [Client::Errors::ServiceError, Client::Errors::ArgumentError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
		# @see Item#restore
		def restore(items, destination: nil, exists: 'FAIL')
			fail Client::Errors::ArgumentError, 
				"Invalid input, expected items" unless items

			FileSystemCommon.validate_item_state(destination)
			destination_url = FileSystemCommon.get_folder_url(destination)

			response = []
			Array(items).each do |item|
				response << restore_item(item, destination_url, exists)
			end
			response
		end
		
		# @return [Array<File, Folder>] items in trash
		# @raise [Client::Errors::ServiceError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
		def browse_trash
			response = @client.browse_trash
			FileSystemCommon.create_items_from_hash_array(response.fetch(:items), 
					@client, in_trash: true)
		end
	
		# List versions of file
		# @param item [File, String]
		# @return [Array<File>] versions of file
		# @raise [Client::Errors::ServiceError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
		# @see Item#versions
		def list_file_versions(item)
			fail Client::Errors::ArgumentError, 
				"Invalid input, expected Item or string path" if Client::Utils.is_blank?(item)

			if item.is_a?(String)
				response = @client.list_file_versions(item)
				FileSystemCommon.create_items_from_hash_array(response, 
						@client, parent: item)
			else
				item.versions
			end
		end

		# List user's shares
		# @return [Array<Share>] shares
		# @raise [Client::Errors::ServiceError]
		def list_shares
			response = @client.list_shares
			FileSystemCommon.create_items_from_hash_array(response, @client)
		end

		# Create share of paths in user's filesystem
		# @param items [Array<File, Folder, String>] file, folder or url
		# @return [Share] instance
		# @raise [Client::Errors::ServiceError, Client::Errors::ArgumentError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
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

		private :restore_item, :get_root
	end
end
