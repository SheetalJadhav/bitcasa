require_relative './item.rb'
require_relative './share.rb'

module Bitcasa
	# Provides common filesystem operations consumed by other classes
	module FileSystemCommon

		# Create item from hash
		# @param client [Bitcasa::Client] restful client instance
		# @option parent [Item|String] parent item of type folder
		# @option in_trash [Boolean] set true to specify, item exists in trash
		# @option keywords or hash containing key/value pairs of item properties
		# @return [File|Folder|Share] item
		# @raise Bitcasa::Client::Error
		def self.create_item_from_hash(client, parent: nil, 
				in_trash: false, **hash)
			
			if hash.key?(:share_key)
				return Share.new(client, **hash)
			end
			unless hash.key?(:type)
				raise Bitcasa::Client::InvalidArgumentError, "Did not recognize item"
			end
			
			hash[:type] = "folder" if hash[:type] == "root"
			if (hash[:type] == "folder")
				return Folder.new(client, parent: parent, in_trash: in_trash, **hash)
			else 
				return File.new(client, parent: parent, in_trash: in_trash, **hash)
			end
		end
		
		# Create array items from corresponding array of hashes
		# @param hashes [Hash []] array of hashes containing key/value properties of items
		# @param client [Bitcasa::Client] restful client instance
		# @option parent [Item|String] parent item of type folder
		# @option in_trash [Boolean] set true to specify, items exists in trash
		# @return [File|Folder|Share][] items
		# @raise Bitcasa::Client::Error
		def self.create_items_from_hash_array(hashes, client, 
				parent: nil, in_trash: false)
			items = []
			hashes.each do |item|
				resp = create_item_from_hash(client, parent: parent, 
						in_trash: in_trash, **item)
				items << resp
			end
			items
		end
		
		# Get folder url
		# @param folder [Item|String]
		# @return [String] url of item
		# @raise Bitcasa::Client::InvalidArgumentError
		def self.get_folder_url(folder)
			return nil if Utils::is_blank?(folder)
			return folder.url if (folder.respond_to?(:url) && 
					folder.respond_to?(:type) && (folder.type == "folder"))
			return folder if folder.is_a?(String)
			raise Bitcasa::Client::InvalidArgumentError, 
				"Invalid input, expected destination item of type folder or string"
		end

		# Get item url
		# @param folder [File|Folder|String]
		# @return [String] url of item
		# @raise Bitcasa::Client::InvalidArgumentError
		def self.get_item_url(item)
			return nil if Utils::is_blank?(item)
			return item.url if item.respond_to?(:url)
			return item if item.is_a?(String)
			raise Bitcasa::Client::InvalidArgumentError, 
				"Invalid input, expected destination item of type file, folder or string"
		end

		# Get item name
		# @param folder [File|Folder|String]
		# @return [String] name of item
		# @raise Bitcasa::Client::InvalidArgumentError
		def self.get_item_name(item)
			return nil if Utils::is_blank?(item)
			return item.name if item.respond_to?(:name)
			return item if item.is_a?(String)
			raise Bitcasa::Client::InvalidArgumentError, 
				"Invalid input, expected destination item of type file, folder or string"
		end

	end
end	
