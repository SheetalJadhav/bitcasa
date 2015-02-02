require_relative 'item'
require_relative 'client'
require_relative 'filesystem_common'

module Bitcasa
	# Bitcasa Container class is base class for folder class
	class Container < Item
		# List contents of this container
		#
		# @return [Array<Folder, File>] list of items
		# @raise [Client::Errors::ServiceError, Client::Errors::ArgumentError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
		def list
			fail Client::Errors::InvalidItemError, 
				"Operation not allowed as item does not exist anymore" unless exists?

			if @in_trash
				response = @client.browse_trash(path: url)
				response = response.fetch(:items)
			else
				response = @client.list_folder(path: url, depth: 1)
			end
			FileSystemCommon.create_items_from_hash_array(response, 
					@client, parent: url, in_trash: @in_trash)
		end

		# Create folder under this container
		#
		# @param item [Folder, String] string or folder object's name will be used
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME', 'REUSE') action to take 
		#		if the item already exists, defaults "FAIL"
		#
		# @return [Folder] instance
		# @raise [Client::Errors::ServiceError, Client::Errors::ArgumentError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
		# @review Behaviour in case item param is a Folder object
		def create_folder(item, exists: 'FAIL')
			raise Client::Errors::ArgumentError, 
				"Invalid input, expected items" if Client::Utils.is_blank?(item)
			FileSystemCommon.validate_item_state(self)	
			
			name = FileSystemCommon.get_item_name(item)
			
			response = @client.create_folder(name, path: url, exists: exists)
			FileSystemCommon.create_item_from_hash(@client, parent: url, **response)
		end

		
		# overriding inherited properties that are not not valid for folder
		private :extension, :extension=, :mime, :mime=, :blocklist_key, 
			:blocklist_id, :is_mirrored, :size, :versions
	end
end
