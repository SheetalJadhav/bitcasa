require_relative 'container'
require_relative 'filesystem_common'


module Bitcasa
	# Represents a folder in the user's filesystem that can contain files and other folders.
	#
	#	@author Mrinal Dhillon
	#	@example
	#		folder = session.filesystem.root.create_folder("testfolder")
	#		folder.name = "newname"
	#		folder.save
	#		file = folder.upload("/tmp/testfile")
	#		folder.list		#=> Array<File, Folder>
	class Folder < Container
		# Upload file to this folder
		#
		# @param filepath [String] local file path
		# @param name [String] (nil) name of uploaded file, default is basename of filepath
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') 
		#		action to take in case of a conflict with an existing folder, default 'FAIL'
		#
		# @return [File] new File object
		# @raise [Client::Errors::ServiceError, Client::Errors::ArgumentError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
		def upload(filepath, name: nil, exists: 'FAIL')
			FileSystemCommon.validate_item_state(self)

			::File.open(filepath, "r") do |file|
				response = @client.upload(url, file, name: name, exists: exists)
				FileSystemCommon.create_item_from_hash(@client, 
						parent: url, **response)
			end
		end
		
		# overriding inherited properties that are not not valid for folder
		private :extension, :extension=, :mime, :mime=, :blocklist_key, 
			:blocklist_id, :is_mirrored, :size, :versions
	end
end
