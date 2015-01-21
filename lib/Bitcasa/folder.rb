require_relative './container.rb'
module Bitcasa
    # Bitcasa Folder Class
	class Folder < Container
		
		# Upload file to this folder
		# @param filepath [String] local file path
		# @option name [String] name of uploaded file, default basename of filepath
		# @option exists ["FAIL"|"OVERWRITE"|"RENAME"|"REUSE"] action to take if the name of the file being uploaded conflicts with an existing file
		# @return Bitcasa::File object
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def upload(filepath, name: nil, exists: 'FAIL')
			response = @client.upload(url, filepath, name: name, exists: exists)
			FileSystemCommon::create_item_from_hash(@client, 
					parent: url, **response)
		end

	end
end
