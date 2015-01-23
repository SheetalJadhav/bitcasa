module Bitcasa
	# Bitcasa Container class 
	class Container < Item
		
		# List contents of this container
		# @return array containing list of items
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def list
			raise Bitcasa::Client::InvalidItemError, 
				"Operation not allowed as item does not exist anymore" unless @exists

			if @in_trash
				# REVIEW: Browse trash returns all items under given path, 
				#		test for parent url
				response = @client.browse_trash(path: url)
			else
				response = @client.list_folder(path: url, depth: 1)
			end
			FileSystemCommon::create_items_from_hash_array(response, 
					@client, parent: url, in_trash: @in_trash)
		end

		# Create folder under this container
		# @param item [Folder|String] string or item's name will be used
		# @option exists ["FAIL"|"OVERWRITE"|"RENAME"|"REUSE"] action to take if the item already exists, defaults "FAIL"
		# @return Folder instance
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		# REVIEW: Behaviour in case item param is a Folder object
		def create_folder(item, exists: 'FAIL')
			raise Bitcasa::Client::InvalidArgumentError, 
				"Invalid input, expected items" if Utils::is_blank?(item)
			FileSystemCommon::validate_item_state(self)	
			
			name = FileSystemCommon::get_item_name(item)
			
			response = @client.create_folder(url, name, exists: exists)
			FileSystemCommon::create_item_from_hash(@client, parent: url, **response)
		end
	end
end
