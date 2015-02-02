require_relative 'filesystem_common'
require_relative 'client'

module Bitcasa
	# An object managed by CloudFS. An item can be either a file or folder. 
	#
	#	Item is the base class for File, Container whereas Folder is derived from Container
	#	Provides common apis for files, folders
	# @author Mrinal Dhillon
	class Item	
				
		# @return [String] the internal id of item that is right most path segment in url
		attr_reader :id

		#	@return [String] id of parent of item
		attr_reader :parent_id

		# @return [String]	type of item, either file or folder
		attr_reader :type
		
		#	@return [String] known current version of item
		attr_reader :version

		# @return [Boolean] indicating whether the item was created by mirroring a file 
		attr_reader :is_mirrored
		
		#	@return [String] blocklist_key of file
		attr_reader :blocklist_key

		#	@return [String] blocklist_id of file
		attr_reader :blocklist_id

		#	@return [Fixnum] file size in bytes
		attr_reader :size
		
		# @return [String] absolute path of item in user's account	
		attr_reader :url
	
		# name of item	
		# @overload name
		# 	@return [String] name of item
		# @overload name=(value)
		# 	@param value [String]
		# 	@raise [Client::Errors::InvalidItemError, 
		#			Client::Errors::OperationNotAllowedError]
		attr_accessor :name

		#	seconds since item was created
		# @overload date_created
		#		@return [Timestamp] creation time in seconds since epoch
		# @overload date_created=(value)
		# 	@param value [Timestamp]
		# 	@raise [Client::Errors::InvalidItemError, 
		#			Client::Errors::OperationNotAllowedError]
		attr_accessor :date_created
	
		#	seconds since metadata of the item was last modified
		# @overload date_meta_last_modified
		#		@return [Timestamp] time in seconds since epoch at metadata was last modified
		# @overload date_meta_last_modified=(value)
		# 	@param value [Timestamp]
		# 	@raise [Client::Errors::InvalidItemError, 
		#			Client::Errors::OperationNotAllowedError]
		attr_accessor :date_meta_last_modified

		#	seconds since content of the item was last modified
		# @overload date_content_last_modified
		#		@return [Timestamp] time in seconds since epoch at content was last modified
		# @overload date_content_last_modified=(value)
		# 	@param value [String]
		# 	@raise [Client::Errors::InvalidItemError, 
		#			Client::Errors::OperationNotAllowedError]
		attr_accessor :date_content_last_modified

		# mime type of file
		# @overload mime
		# 	@return [String] mime type of file	
		# @overload mime=(value)
		# 	Set new file mime type by including extension in the name of the file. 
		#		CloudFS will assign the mime type based on the name
		# 	@param value [String]
		# 	@raise [Client::Errors::InvalidItemError, 
		#			Client::Errors::OperationNotAllowedError]
		attr_accessor :mime
	
		#	extension of item of type file	
		# @overload extension
		# 	@return [String] extension of file
		# @overload extension=(value)
		#		Set new file extension by including the extension in the name of file. 
		#		CloudFS will assign the extension based on the name
		# 	@param value [String]
		# 	@raise [Client::Errors::InvalidItemError, 
		#			Client::Errors::OperationNotAllowedError]
		attr_accessor :extension 
		
		# extra metadata of item	
		#	@overload application_data
		#		@return [Hash] extra metadata of item
		# @overload application_data=(hash={})
		# 	Sets application_data
		# 	@param hash [Hash]
		# 	@raise [Client::Errors::InvalidItemError, 
		#			Client::Errors::OperationNotAllowedError]
		attr_accessor :application_data

#		attr_reader :client
#		attr_reader :in_trash
#		attr_reader :in_share
#		attr_reader :exists 
#		attr_reader :changed_properties
		
		# @param client [Client] restful Client instance
		# @param parent [Item, String] default: ("/") parent folder item or url
		# @param in_trash [Boolean] set true to specify item exists in trash
		# @param in_share [Boolean] set true to specify item exists in share
		# @param [Hash] properties metadata of item
		# @option properties [String] :id path id of item
		# @option properties [String] :parent_id (nil) pathid of parent of item
		# @option properties [String] :type (nil) type of item either file, folder
		# @option properties [String] :name (nil)
		# @option properties [Timestamp] :date_created (nil)
		# @option properties [Timestamp] :date_meta_last_modified (nil)
		# @option properties [Timestamp] :date_content_last_modified (nil)
		# @option properties [Fixnum] :version (nil)
		# @option properties [Boolean] :is_mirrored (nil)
		# @option properties [String] :mime (nil) applicable to item type file only
		# @option properties [String] :blocklist_key (nil) applicable to item type file only
		# @option properties [String] :blocklist_id (nil) applicable to item type file only
		# @option properties [Fixnum] :size (nil) applicable to item type file only
		# @option properties [Hash] :application_data ({ }) extra metadata of item
		# @raise [Client::Errors::ArgumentError]
		def initialize(client, parent: nil, in_trash: false, 
				in_share: false, **properties)
			fail Client::Errors::ArgumentError, 
				"Invalid client, input type must be Bitcasa::Client" unless client.is_a?(Client)
			
			@client = client
			set_item_properties(parent: parent, in_trash: in_trash, 
					in_share: in_share, **properties)	
		end
		
		# @see #initialize
		# @review required properties
		def set_item_properties(parent: nil, in_trash: false, 
				in_share: false, **params)
			# id, type and name are required instance variables
			@id = params.fetch(:id) {
				fail Client::Errors::ArgumentError, "Provide item id"}
			@type = params.fetch(:type) {
				fail Client::Errors::ArgumentError, "Provide item type"}
			@name = params.fetch(:name) {
				fail Client::Errors::ArgumentError, "Provide item name"}

			@type = "folder" if @type == "root"	
			@parent_id = params[:parent_id]
			@date_created = params[:date_created]
			@date_meta_last_modified = params[:date_meta_last_modified]
			@date_content_last_modified = params[:date_content_last_modified]
			@version = params[:version]

			if @type == "file"
				@is_mirrored = params[:is_mirrored]
				@mime = params[:mime]
				@blocklist_key = params[:blocklist_key]
				@extension = params[:extension]
				@blocklist_id = params[:blocklist_id]
				@size = params[:size]
			end

			@application_data = params[:application_data]
			@in_trash = in_trash
			@in_share = in_share
			@exists = true

			set_url(parent)
			changed_properties_reset
		end

		#	@return [Boolean] whether the item exists in trash 
		def in_trash?
			@in_trash
		end

		#	@return [Boolean] whether the item exists in share 
		def in_share?
			@in_share
		end

		# @return [Boolean] whether item exists, false if item 
		#		has been deleted permanently
		def exists?
			@exists
		end

		#	@return [Boolean] whether the item exists		
		def exists?
			@exists
		end

		# Reset changed properties
		def changed_properties_reset
			@changed_properties = {application_data: {}}
		end
		
		# see #name
		def name=(value)
			FileSystemCommon.validate_item_state(self)
			@name = value
			@changed_properties[:name] = value
		end
		
		# @see #extension
		def extension=(value)
			fail OperationNotAllowedError, 
				"Operation not allowed for item of type #{@type}" unless @type == "file"
			FileSystemCommon.validate_item_state(self)
			@extension = value
			@changed_properties[:extension] = value
		end
	
		# @see #date_created
		def date_created=(value)
			FileSystemCommon.validate_item_state(self)
			@date_created = value
			@changed_properties[:date_created] = value
		end

		# @see #date_meta_last_modified
		def date_meta_last_modified=(value)
			FileSystemCommon.validate_item_state(self)
			@date_meta_last_modified = value
			@changed_properties[:date_meta_last_modified] = value
		end

		# @see #date_content_last_modified
		def date_content_last_modified=(value)
			FileSystemCommon.validate_item_state(self)
			@date_content_last_modified = value
			@changed_properties[:date_content_last_modified] = value
		end

		# see #mime
		def mime=(value)
			fail OperationNotAllowedError, 
				"Operation not allowed for item of type #{@type}" unless @type == "file"
			FileSystemCommon.validate_item_state(self)
			@mime = value
			@changed_properties[:mime] = value
		end
	
		#	@see #application_data
		# @todo support update of nested hash, currently overwrites nested hash	
		def application_data=(hash={})
			FileSystemCommon.validate_item_state(self)
			if @application_data 
					@application_data = @application_data.merge(hash)
			else
					@application_data = hash
			end
			@changed_properties[:application_data] = 
				@changed_properties[:application_data].merge(hash)
		end
		
		# Move this item to destination folder
		# @note	Updates this item and it's refrence is returned.
		# @note Locally changed properties get discarded
		#
		# @param destination [Item, String] destination to move item to, should be folder
		# @param name [String] (nil) new name of moved item
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') 
		#		action to take in case of a conflict with an existing folder, default 'RENAME'
		#
		# @return [Item] refrence to this item object
		# @raise [Client::Errors::ServiceError, Client::Errors::ArgumentError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
		def move_to(destination, name: nil, exists: 'RENAME')
			FileSystemCommon.validate_item_state(self)
			FileSystemCommon.validate_item_state(destination)
	
			destination_url = FileSystemCommon.get_folder_url(destination)	
			name = @name unless name
		
			if @type == "folder"
				response = @client.move_folder(url, destination_url, name, exists: exists)
			else
				response = @client.move_file(url, destination_url, name, exists: exists)
			end
				# Overwrite this item's properties with Moved Item's properties
				set_item_properties(parent: destination_url, **response)	
			self
		end

		# Copy this item to destination
		# @note	Locally changed properties are not copied
		#
		# @param destination [Item, String] destination to copy item to, should be folder
		# @param name [String] (nil) new name of copied item
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') 
		#		action to take in case of a conflict with an existing folder, default 'RENAME'
		# @return [Item] new instance of copied item
		# @raise [Client::Errors::ServiceError, Client::Errors::ArgumentError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
		def copy_to(destination, name: nil, exists: 'RENAME')
			FileSystemCommon.validate_item_state(self)
			FileSystemCommon.validate_item_state(destination)

			destination_url = FileSystemCommon.get_folder_url(destination)	
			name = @name unless name
		
			if @type == "folder"
				response = @client.copy_folder(url, destination_url, 
						name, exists: exists)
			else
				response = @client.copy_file(url, destination_url, 
						name, exists: exists)
			end
				FileSystemCommon.create_item_from_hash(@client, 
						parent: destination_url, **response)
		end

		# Delete this item
		# @note Updates this item if operation is successful
		# @note	Locally changed properties get discarded
		#
		# @param force [Boolean] (false) set true to delete non-empty folder		
		# @param commit [Boolean] (false) set true to remove item permanently, 
		#		else will be moved to trash, Client::Errors::InvalidItemError is raised
		#		for subsequent operation if commit: true
		# @param raise_exception [Boolean] (false)
		#		method suppresses exceptions and returns false if set to false, 
		#			added so that consuming application can control behaviour
		#
		# @return [Boolean] true/false
		# @raise [Client::Errors::ServiceError, Client::Errors::ArgumentError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
		#		if raise_exception is true
		def delete(force: false, commit: false, raise_exception: false)
			FileSystemCommon.validate_item_state(self, in_trash: false)

			if @in_trash
				# @review NOOP if commit is false since item is already in trash, return true
				if commit
					@client.delete_trash_item(path: url)
					@exists = false
					@in_trash = false
				end
				return true
			end

			if @type == "folder"
				@client.delete_folder(url, force: force, commit: commit)
			else
				@client.delete_file(url, commit: commit)
			end
		
			if commit
				@exists = false 
				@in_trash = false
			else
				@application_data[:_bitcasa_original_path] = ::File.dirname(url)
				set_url(nil)
		 		@in_trash = true
			end	
				changed_properties_reset	
			true
			rescue Client::Errors::ServiceError, 
				Client::Errors::OperationNotAllowedError, Client::Errors::InvalidItemError
				raise $! if raise_exception == true
				false
		end
		
		# Get this item's properties from server
		# @return [Hash] metadata of this item
		# @raise [Client::Errors::ServiceError]
		def get_properties_from_server
			if @in_trash == true
				response = @client.browse_trash(path: url)
				properties = response.fetch(:meta)
			elsif @type == "folder"
				properties = @client.get_folder_meta(url)
			else
				properties = @client.get_file_meta(url)
			end
			properties
		end

		# Refresh this item's properties from server
		#	@note	Locally changed properties get discarded
		# @return [void]
		# @raise [Client::Errors::ServiceError, Client::Errors::InvalidItemError]
		def refresh
			FileSystemCommon.validate_item_state(self, exists: true)
			
			if @in_trash == true
				response = @client.browse_trash(path: url)
				properties = response.fetch(:meta)
			elsif @type == "folder"
				properties = @client.get_folder_meta(url)
			else
				properties = @client.get_file_meta(url)
			end
			set_item_properties(in_trash: @in_trash, in_share: @in_share, **properties)
		end

		# Sets restored item's url and properties based on exists and destination url
		#		This method is called to update this item after it has been restored.
		#		If exist == 'Fail' then this item's expected url is its orginal path
		#			elseif exists == 'RESCUE' the url should be destination_url/(item's trashid)
		#			elseif exists == 'RECREATE' then url should be 
		#					(url of named path)/(item' trashid)
		#
		# @param destination_url [String] ('RESCUE' (default root), RECREATE(named path))
		#		path depending on exists option to place item into 
		#		if the original path does not exist.
		# @param exists [String] ('FAIL', 'RESCUE', 'RECREATE') 
		#		action to take if the recovery operation encounters issues, default 'FAIL'
		#
		# @raise [Client::Errors::ServiceError, Client::Errors::ArgumentError]
		def set_restored_item_properties(destination_url, exists)
			begin
				parent_url = @application_data[:_bitcasa_original_path]
				properties = FileSystemCommon.get_item_properties_from_server(@client, 
						parent_url, @id, @type)
			rescue
				raise $! if exists == "FAIL"

				if exists == "RESCUE"
					parent_url = destination_url
					properties = FileSystemCommon.get_item_properties_from_server(@client, 
							parent_url, @id, @type)
				elsif exists == "RECREATE"
			 		response = FileSystemCommon.get_properties_of_named_path(@client, 
							destination_url)
					parent_url = response[:url] 
					properties = FileSystemCommon.get_item_properties_from_server(@client,
						 	parent_url,	@id, @type)
				end
			end
			set_item_properties(parent: parent_url, in_trash: false, **properties)
		end	

		# Restore this item from trash
		# @note This item's properties are updated if success
		#
		# @param destination [Folder, String] ('RESCUE' (default root), 
		#		RECREATE(named path)) path depending on exists option to place item into 
		#		if the original path does not exist.
		# @param exists [String] ('FAIL', 'RESCUE', 'RECREATE') 
		#		action to take if the recovery operation encounters issues, default 'FAIL'
		# @param raise_exception [Boolean] (false)
		#		method suppresses exceptions and returns false if set to false, 
		#			added so that consuming application can control behaviour
		# 
		# @return [Boolean] true/false
		# @raise [Client::Errors::ServiceError, Client::Errors::ArgumentError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
		#		if raise_exception is true
		#
		# @note exist: 'RECREATE' with named path is expensive operation 
		#		as items in named path hierarchy are traversed 
		#		in order to fetch Restored item's propererties.
		# @example
		#		item.restore
		#		item.restore("/FOPqySw3ToK_25y-gagUfg", exists: 'RESCUE')
		#		item.restore(folderobj, exists: 'RESCUE')
		#		item.restore("/depth1/depth2", exists: 'RECREATE')
		def restore(destination: nil, exists: 'FAIL', raise_exception: false)
			fail Client::Errors::OperationNotAllowedError, 
				"Item needs to be in trash for Restore operation" unless @in_trash
			FileSystemCommon.validate_item_state(destination)

			destination_url = FileSystemCommon.get_folder_url(destination)	
			@client.recover_trash_item(url, destination: destination_url, restore: exists)
			
			set_restored_item_properties(destination_url, exists)
			true
			rescue Client::Errors::ServiceError, Client::Errors::ArgumentError, 
				Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError
				raise $! if raise_exception == true
				false
		end

		# List versions of this item if file
		#
		# @return [Array<Item>] items
		#	@raise [Client::Errors::ServiceError, Client::Errors::ArgumentError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
		def versions
			# @review confirm if versions should be allowed for items in trash, in share 
			FileSystemCommon.validate_item_state(self, in_trash: false, in_share: false)
			# @review could return self in case of folder as folder has only current version
			fail OperationNotAllowedError, 
				"Opertaion not allowed for item of type #{@type}" unless @type == "file"
				
			response = @client.list_file_versions(url)
			FileSystemCommon.create_items_from_hash_array(response, @client, 
					parent: url, in_share: @in_share, in_trash: @in_trash)
		end

		# Save this item's current state to bitcasa
		#		Locally saved properties are commited to item in user's account
		#
		# @param version_conflict [String] ('FAIL', 'IGNORE') action to take 
		#		if the version on this item does not match the version on the server
		# 
		# @return [void]
		#	@raise [Client::Errors::ServiceError, Client::Errors::ArgumentError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
		def save(version_conflict: 'FAIL')
			FileSystemCommon.validate_item_state(self)
			return nil if Client::Utils.is_blank?(@changed_properties)

			if @type == "folder"
				@client.alter_folder_meta(url, @version, 
						version_conflict: version_conflict, **@changed_properties)
			else
				@client.alter_file_meta(url, @version, 
						version_conflict: version_conflict, **@changed_properties)
			end
			# @review should this item to be updated with returned meta
			changed_properties_reset 
			nil
		end

		# Gets properties in hash format
		# @return [Hash] metadata of item
		def get_properties_in_hash
			properties = {
				:'name' => "#{@name}",
				:'date_created' => "#{@date_created}",
				:'date_meta_last_modified' => "#{@date_meta_last_modified}",
				:'date_content_last_modified' => "#{@date_content_last_modified}",
				:'extension' => "#{@extension}",
				:'mime' => "#{@mime}",
				:'application_data' => @application_data
			}
			properties
		end

		# Sets the url of item
		# @param parent [Folder, String]
		# @return [void]
		def set_url(parent)
			parent_url = FileSystemCommon.get_folder_url(parent)
			@url = parent_url == "/" ? "/#{@id}" : "#{parent_url}/#{@id}"
		end
	
		private :set_item_properties, :changed_properties_reset, 
			:set_restored_item_properties, :get_properties_in_hash, :set_url
	end
end
