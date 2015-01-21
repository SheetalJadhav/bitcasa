require_relative "./item.rb"

module Bitcasa
	# File class is aimed to provide native File object like interface to bitcasa cloudfs files
	# TODO: InputStream read()
	class File < Item
		attr_reader :offset

		def initialize(client, parent: nil, in_trash: false, **params)
			super
			@offest = 0
		end
		
		# Downlaod this file to local directory
		# @param local_path [String] absolute path of local directory
		# @option filename [String] name of downloaded file, default is name of this file
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def download(local_path, filename: nil)
			raise Bitcasa::Client::Error, "local path is not a valid directory" unless ::File.directory?(local_path)
			
			if filename.nil?
				file_name = self.name
			else
			 file_name = filename
			end

			if local_path[(local_path.length) - 1] == '/'
				local_filepath = "#{local_path}#{file_name}"
			else
				local_filepath = "#{local_path}/#{file_name}"
			end
			
			path = self.absolute_path
			file = nil
			file = ::File.open(local_filepath, 'wb')
			
			@client.download(path) do |buffer|
				file.write(buffer)
			end
		ensure
				file.close unless file.nil?
		end
	end
end

=begin TODO: Following logic is copied directly from Python SDK, review, test and checkin
	def read(size: 0)
		offset = self.offset
		content = @client.download(self.absolute_path, startbyte: offset, bytecount: size)
		offset += size 
		content
	end	

	def tell
		@offest
	end

	def seek(offset, whence: 0)
		if whence == 0
			@offset  = offset
		if whence == 1
			@offset +=offset
		if whence == 2
			@offset = @size - @offset 
	
		if offset > @size
			offset = @size
		if offset < 0
				offset = 0

		offset
	end
end
=end
