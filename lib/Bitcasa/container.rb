module Bitcasa
	# Bitcasa Container class 
	class Container < Item
		
		# List contents of this container
		# @return array containing list of items
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def list
			response = @client.list_folder(path: url, depth: 1)
			FileSystemCommon::create_items_from_hash_array(response, 
					@client, parent: url)
		end

		# Create folder under this container
		# @param item [File|Folder|String] string or item's name will be used
		# @option exists ["FAIL"|"OVERWRITE"|"RENAME"|"REUSE"] action to take if the item already exists, defaults "FAIL"
		# @return Folder instance
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def create_folder(item, exists: 'FAIL')
			raise Bitcasa::Client::InvalidArgumentError, 
				"Invalid input, expected items" if Utils::is_blank?(item)
			
			name = FileSystemCommon::get_item_name(item)
			
			response = @client.create_folder(url, name, exists: exists)
			FileSystemCommon::create_item_from_hash(@client, parent: url, **response)
		end
	end
end
