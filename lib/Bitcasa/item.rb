
module Bitcasa
	# Class item represents a Bitcasa file, folder
	# TODO: Update restored item's properties and url,
	#				Raise invalid item for item that does not exists i.e. delete with commit: true and delete in trash item,
	#				Maintain changed property list for item properties that have been update by user,
	#				Save should update only the changed property list for that item on bitcasa server,
	# 			NoMethodError if item is not a file or folder, not handling since no other type is supported
	# 			Operation not allowed if items in share or trash,
	#				URL/PATH validation regex  
	class Item	

		attr_accessor :id, :parent_id, :type, :name, :date_created, 
			:date_meta_last_modified, :date_content_last_modified, :version, 
			:is_mirrored, :mime, :blocklist_key, :extension, :blocklist_id, :size, 
			:application_data, :absolute_path
		
		attr_reader :client, :in_trash
		
		# @param client restful Client instance
		# @option parent [Item|String] parent item of type folder
		# @option in_trash [Boolean] set true to specify item exists in trash
		# @option keywords or hash containing following key/value pairs
		def initialize(client, parent: nil, in_trash: false, **params)
			raise Bitcasa::Client::InvalidArgumentError, "invalid client, input type must be Bitcasa::Client" unless client.is_a?(Bitcasa::Client)
			
			@client = client
			set_item_properties(parent: parent, in_trash: in_trash, **params)	
		end
		
		# @option parent [Item|String] parent item of type folder
		# @option in_trash [Boolean] set true to specify item exists in trash
		# @option keywords or hash containing following key/value pairs
		def set_item_properties(parent: nil, in_trash: false, **params)
			@id = params[:id]
			@parent_id = params[:parent_id]
			@type = params[:type]
			@name = params[:name]
			@date_created = params[:date_created]
			@date_meta_last_modified = params[:date_meta_last_modified]
			@date_content_last_modified = params[:date_content_last_modified]
			@version = params[:version]
			@is_mirrored = params[:is_mirrored]
			@mime = params[:mime]
			@blocklist_key = params[:blocklist_key]
			@extension = params[:extension]
			@blocklist_id = params[:blocklist_id]
			@size = params[:size]
			@application_data = params[:application_data]
			@in_trash = in_trash
			set_url(parent)
		end

		def url
			@absolute_path
		end

		# Move this item to destination folder
		# @param destination [Item|String] destination to move item to, should be folder
		# @option name [String] name of moved item
		# @option exists ["FAIL"|"OVERWRITE"|"RENAME"] action to take in case of a conflict with an existing item in destination folder, default "RENAME"
	 	# @return Item instance containing metadata of moved item
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def move_to(destination, name: nil, exists: 'RENAME')
			destination_url = FileSystemCommon::get_folder_url(destination)	
			name = @name unless name
		
			if @type == "folder"
				response = @client.move_folder(url, destination_url, name, exists: exists)
			else
				response = @client.move_file(url, destination_url, name, exists: exists)
			end
				set_item_properties(parent: destination_url, **response)	
			self
		end
		
		# Copy this item to destination
		# @param destination [Item|String] destination to copy item to, should be folder
		# @option name [String] name of copied item
		# @option exists ["FAIL"|"OVERWRITE"|"RENAME"] action to take in case of a conflict with an existing item in destination folder, default "RENAME"
	 	# @return Item instance containing metadata of copied item
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def copy_to(destination, name: nil, exists: 'RENAME')
			destination_url = FileSystemCommon::get_folder_url(destination)	
			name = @name unless name
		
			if @type == "folder"
				response = @client.copy_folder(url, destination_url, 
						name: name, exists: exists)
			else
				response = @client.copy_file(url, destination_url, 
						name: name, exists: exists)
			end
				FileSystemCommon::create_item_from_hash(@client, 
						parent: destination_url, **response)
		end

		# Delete this item
		# @option commit [boolean] default false, set true to remove item permanently, else will be moved to trash, default false 
		# @option force [boolean] default false, set true to delete non-empty folder, defailt false
		# @return true/false
		# @raise Bitcasa::Client::Error
		def delete(force: false, commit: false)
		
			if @in_trash
				# REVIEW: NOOP if commit is false since item is already in trash
				@client.delete_trash_item(url) if commit
				return true
			end

			if @type == "folder"
				@client.delete_folder(url, force: force, commit: commit)
			else
				@client.delete_file(url, commit: commit)
			end
			@in_trash = true if commit
			true
			rescue Bitcasa::Client::Error
				false
		end

		# Restore this item, if in trash
		# @option destination [Item|String] rescue or recreate(default root) path depending on exists option, should be folder
		# @option exists ["FAIL"|"RESCUE"|"RECREATE"] action to take if the recovery operation encounters issues, default 'FAIL'
		# @return true/false
		# @raise Bitcasa::Client::Error
		def restore(destination: nil, exists: 'FAIL')
			# REVIEW: NOOP if item is not in trash
			return false unless @in_trash

			destination_url = FileSystemCommon::get_folder_url(destination)	
			@client.recover_trash_item(url, destination: destination_url, restore: exists)
			true
			rescue Bitcasa::Client::Error
				false
		end

		# List versions of this item if file
		# @return array of items
		# @raise Bitcasa::Client::Error
		def versions
			# REVIEW: Could return self in case of folder as folder has only current version
			raise NoMethodError, "Undefine method versions for item of type #{@type}" unless @type == "file"

			response = @client.list_file_versions(url)
			FileSystemCommon::create_items_from_hash_array(response, @client, parent: url)
		end

		# Save this item's current state to bitcasa
		# @param version_conflict ["FAIL"|"IGNORE"] action to take if the version on this item does not match the version on the server
		# @raise Bitcasa::Client::Error
		# REVIEW: check if item needs to be updated with returned meta
		def save(version_conflict: 'FAIL')
			properties = get_properties_in_hash
			
			if @type == "folder"
				@client.alter_folder_meta(url, @version, 
						version_conflict: version_conflict, **properties)
			else
				@client.alter_file_meta(url, @version, 
						version_conflict: version_conflict, **properties)
			end
			nil
		end

		# gets properties in hash format
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
		end

		# Sets the absolute path of item
		# @param parent [String]  to set item to folder
		# @param item [item|String] is a File
		def set_url(parent)
			parent_url = FileSystemCommon::get_folder_url(parent)
			@absolute_path = parent_url == "/" ? "/#{@id}" : "#{parent_url}/#{@id}"
		end
		
		private :set_url, :set_item_properties, :get_properties_in_hash
	end
end
