require_relative 'client'

module Bitcasa
	# @private
	# Provides common filesystem operations consumed by other classes
	module FileSystemCommon
		extend self
		# Create item from hash
		# @param client [Client] restful client instance
		# @param [Hash] hash properties of item
		# @option parent [Item, String] parent item of type folder
		# @option in_trash [Boolean] set true to specify, item exists in trash
		# @option in_share [Boolean] set true to specify, item exists in share
		# @option keywords or hash containing key/value pairs of item properties
		# @return [File, Folder, Share] item
		# @raise [Client::Errors::ArgumentError]
		def create_item_from_hash(client, parent: nil, 
				in_trash: false, in_share: false, **hash)
			require_relative 'file'
			require_relative 'folder'
			require_relative 'share'

			return Share.new(client, **hash) if hash.key?(:share_key)
			fail Client::Errors::ArgumentError, 
				"Did not recognize item" unless hash.key?(:type)
			if (hash[:type] == "folder" || hash[:type] == "root")
				Folder.new(client, parent: parent, 
						in_trash: in_trash, in_share: in_share, **hash)
			else 
				File.new(client, parent: parent, 
						in_trash: in_trash, in_share: in_share, **hash)
			end
		end
		
		# Create array items from corresponding array of hashes
		# @param hashes [Array<Hash>] array of hash properties of items
		# @param client [Client] restful client instance
		# @option parent [Item, String] parent item of type folder
		# @option in_trash [Boolean] set true to specify, items exist in trash
		# @option in_share [Boolean] set true to specify, items exist in share
		# @return [Array<File, Folder, Share>] items
		# @raise [Client::Errors::ArgumentError]
		def create_items_from_hash_array(hashes, client, 
				parent: nil, in_trash: false, in_share: false)
			items = []
			hashes.each do |item|
				resp = create_item_from_hash(client, parent: parent, 
						in_trash: in_trash, in_share: in_share, **item)
				items << resp
			end
			items
		end
		
		# Get folder url
		# @param folder [Item, String]
		# @return [String] url of item
		# @raise [Client::Errors::ArgumentError]
		def get_folder_url(folder)
			return nil if Client::Utils.is_blank?(folder)
			return folder.url if (folder.respond_to?(:url) && 
					folder.respond_to?(:type) && (folder.type == "folder"))
			return folder if folder.is_a?(String)
			fail Client::Errors::ArgumentError, 
				"Invalid input of type #{folder.class}, expected destination item of type Bitcasa::Folder or string"
		end

		# Get item url
		# @param item [File, Folder, String]
		# @return [String] url of item
		# @raise [Client::Errors::ArgumentError]
		def get_item_url(item)
			return nil if Client::Utils.is_blank?(item)
			return item.url if item.respond_to?(:url)
			return item if item.is_a?(String)
			fail Client::Errors::ArgumentError, 
				"Invalid input, expected destination item of type file, folder or string"
		end

		# Get item name
		# @param item [File, Folder, String]
		# @return [String] name of item
		# @raise [Client::Errors::ArgumentError]
		def get_item_name(item)
			return nil if Client::Utils.is_blank?(item)
			return item.name if item.respond_to?(:name)
			return item if item.is_a?(String)
			fail Client::Errors::ArgumentError, 
				"Invalid input, expected destination item of type file, folder or string"
		end

		# Validate item's current state for operations
		# @param item [Item] item to validate
		# @option in_trash [Boolean] set false to avoid check if item in trash
		# @option in_share [Boolean] set false to avoid check if item in share
		# @option exists [Boolean] set false to avoid check if item exists
		# @raise [Client::Errors::InvalidItemError, 
		#		Client::Errors::OperationNotAllowedError]
		def validate_item_state(item, in_trash: true, in_share: true, exists: true) 
			require_relative 'item'
			return nil unless item.kind_of?(Item)
			fail Client::Errors::InvalidItemError, 
				"Operation not allowed as item does not exist anymore" if (exists && item.exists? == false)
			fail Client::Errors::OperationNotAllowedError, 
				"Operation not allowed as item is in trash" if (in_trash && item.in_trash?)
			fail Client::Errors::OperationNotAllowedError, 
				"Operation not allowed as item is in share" if (in_share && item.in_share?)
		end

		# Validate share's current state for operations
		# @param share [Share] share instance to validate
		# @option exists [Boolean] set false to avoid check if share exists
		# @raise [Client::Errors::InvalidShareError, 
		#		Client::Errors::ArgumentError]
		def validate_share_state(share, exists: true) 
			require_relative 'share'
			fail Client::Errors::ArgumentError, 
				"Invalid object of type #{share.class}, expected Share" unless share.kind_of?(Share)
			fail Client::Errors::InvalidShareError, 
				"Operation not allowed as share does not exist anymore" if (exists && share.exists? == false)
		end


		# Fetches properties of named path by recursively listing each member 
		#			starting root with depth 1 and filter=name=path_member
		# @param client [Client] restful client instance
		# @option named_path [String] named (not pathid) cloudfs path of item i.e. /a/b/c
		# @return [Hash] containing url and meta of item
		# @raise [Client::Errors::ServiceError, Client::Errors::ArgumentError]
		def get_properties_of_named_path(client, named_path)
			fail Client::Errors::ArgumentError, 
				"Invalid input, expected destination string" if Client::Utils.is_blank?(named_path)
 			fail Client::Errors::ArgumentError, 
				"invalid client, input type must be Client" unless client.is_a?(Client)

			named_path = "#{named_path}".insert(0, '/') unless (named_path[0] == '/')
			first, *path_members = named_path.split('/')
			path = first

			response = []
			path_members.each	do |member|
				response = client.list_folder(path: path, depth: 1, 
						filter: "name=#{member}")
				path << "/#{response[0][:id]}"
			end

			{url: path, meta: response[0]}
		end

		# Get an item's properties from server
		#
		# @param client [Client] restful Client instance
		# @param parent_url [String] url of parent
		# @param id [String] pathid of item
		# @param type [String] ("file", "folder")
		# @return [Hash] metadata of item
		#
		# @raise [Client::Errors::ServiceError]
		def get_item_properties_from_server(client, parent_url, id, type, in_trash: false)
			item_url = parent_url == "/" ? "/#{id}" : "#{parent_url}/#{id}"
			if in_trash == true
				response = client.browse_trash(path: item_url)
				properties = response.fetch(:meta)
			elsif type == "folder"
				properties = client.get_folder_meta(item_url)
			else
				properties = client.get_file_meta(item_url)
			end
			properties
		end

	end
end	
