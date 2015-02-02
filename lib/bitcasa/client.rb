require_relative 'client/connection'
require_relative 'client/constants'
require_relative 'client/utils'
require_relative 'client/error'

module Bitcasa
	# Provides low level mapping apis to Bitcasa Cloudfs Service
	#
	#	@author Mrinal Dhillon
	#	Maintains an instance of, Client::Connection class, 
	#		since Client::Connection instance is MT-safe 
	#		and can be called from several threads without synchronization 
	#		after setting up an instance, same behaviour is expected from Client class. 
	#		Should use single instance for all calls per server accross 
	#		multiple threads for performance.
	#
	#
	# @example
	#		Authenticate
	#		client = Bitcasa::Client.new(clientid, secret, host)
	#		client.authenticate('testuser', 'password')
	#		client.ping
	#	@example Upload file
	#		::File.open("/tmp/xyz", "r") do |file|
	#			client.upload(url, file, 
	#					name: 'somename', exists: 'FAIL')
	#		end
	#	@example Download file
	#		Download into buffer
	#		buffer = client.download("pathid", startbyte: 0, bytecount: 1000)
	#
	#		Streaming download i.e. chunks are synchronously returned as soon as available
	#			preferable for large files download:
	#
	#		::File.open(local_filepath, 'wb') do |file|
	#				client.download(url) { |buffer| file.write(buffer) }
	#		end
	#	
	# @optimize Support async requests, 
	#		blocker methods like wait for async operations,
	#		chunked/streaming upload i.e. chunked upload(not sure if server supports), 
	#		StringIO, String upload,
	# 	debug
	class Client

		# Creates Client instance that manages rest api calls to Bitcasa Cloud
		#
		# @param clientid [String] application clientid
		# @param secret [String] application secret
		# @param host [String] server address
		# @optimize timeout options
		# @optimize provide option to load credentials 
		#		and http connection related configuration from config file, env
		def initialize(clientid, secret, host)
			fail Errors::ArgumentError, 
				"Invalid argument provided" if ( Utils.is_blank?(clientid) || 
						Utils.is_blank?(secret) || Utils.is_blank?(host) )
			
			@clientid = "#{clientid}"
			@secret = "#{secret}"
			@host = /https:\/\// =~ host ? "#{host}" : 
					"#{Constants::URI_PREFIX_HTTPS}#{host}"

			@access_token = nil
			# @review setting send and recieve timeout to never in order to support 
			#		large file uploads and downloads
			@http_connection = Connection.new(connect_timeout: 60, 
					send_timeout: 0, receive_timeout: 0)
		end

		# Checks if Client can make authenticated requests to Bitcasa
		# @return [Boolean] (true, false)
		def is_linked?
			linked?
		end
		
		# Checks if Client can make authenticated requests to Bitcasa
		# @return [Boolean] (true, false)
		def linked?
			if Utils.is_blank?(@access_token)
				false
			else
				ping
				true
			end
			rescue Errors::ServiceError
				false
		end

		# Unlinks this client object from bitcasa user's account
		# @note this will disconnect all keep alive connections and internal sessions
		# @return [true]
		def unlink
			if @access_token
				@access_token = ''
				@http_connection.unlink
			end
			true
		end
		
		# Obtains an oauth2 access token end user for an particular client 
		# @param username [String] username of the user
		# @param password [String] password of the user
    # @return [true]
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def authenticate(username, password)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass username" if Utils.is_blank?(username)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass password" if Utils.is_blank?(password)

			date = Time.now.utc.strftime(Constants::DATE_FORMAT)
			form = {
				Constants::PARAM_GRANT_TYPE => Constants::PARAM_PASSWORD, 
				Constants::PARAM_PASSWORD => password, 
				Constants::PARAM_USER => username
			}
		
			headers = {
				Constants::HEADER_CONTENT_TYPE =>
					Constants::CONTENT_TYPE_APP_URLENCODED, 
				Constants::HEADER_DATE => date
			}	

			uri = { endpoint: Constants::ENDPOINT_OAUTH }
			signature = Utils.generate_auth_signature(Constants::ENDPOINT_OAUTH, 
					form, headers, @secret)
			headers[Constants::HEADER_AUTHORIZATION] = 
				"#{Constants::HEADER_AUTH_PREFIX_BCS} #{@clientid}:#{signature}"
			
			access_info = request('POST', uri: uri, header: headers, body: form)
			@access_token = access_info.fetch(:access_token)
			true
		end

		# Ping bitcasa server to verifies the end-user’s access token
		# @return [true]
		# @raise [Errors::ServiceError]
		def ping
			request('GET', uri: { endpoint: Constants::ENDPOINT_PING }, 
				 	header: Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
			true
		end

		# Creates a new end-user account for a Paid CloudFS (developer’s) account
		#
		# @param username [String] username of the end-user.
		# @param password [String] password of the end-user.
		# @param email [String] email of the end-user
		# @param first_name [String] first name of end user
		# @param last_name [String] last name of end user
		#
		# @return [Hash] user's profile information
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def create_account(username, password, email: nil, 
				first_name: nil, last_name: nil)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass username" if Utils.is_blank?(username)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass password" if Utils.is_blank?(password)

			date = Time.now.utc.strftime(Constants::DATE_FORMAT)
			form = {
				Constants::PARAM_PASSWORD => password, 
				Constants::PARAM_USER  => username
			}
	
			form[Constants::PARAM_EMAIL] = email unless Utils.is_blank?(email)
			form[Constants::PARAM_FIRST_NAME] = 
				first_name unless Utils.is_blank?(first_name)
			form[Constants::PARAM_LAST_NAME] = 
				last_name unless Utils.is_blank?(last_name)
			
			headers = {
				Constants::HEADER_CONTENT_TYPE =>
					Constants::CONTENT_TYPE_APP_URLENCODED , 
				Constants::HEADER_DATE => date
			}	
			uri = { endpoint: Constants::ENDPOINT_CUSTOMERS }
			signature = Utils.generate_auth_signature(Constants::ENDPOINT_CUSTOMERS, 
					form, headers, @secret)
			headers[Constants::HEADER_AUTHORIZATION] = 
				"#{Constants::HEADER_AUTH_PREFIX_BCS} #{@clientid}:#{signature}"
			
			request('POST', uri: uri, header: headers,	body: form)
		end	

		# Get bitcasa user profile information
		#
		# @return [Hash] user information
		# @raise [Errors::ServiceError]
		def get_profile
			uri = { endpoint: Constants::ENDPOINT_USER_PROFILE }
			
			request('GET', uri: uri, 
					header: Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
		end

		# Create folder
		#
		# @param name [Sting] name of folder to create
		#	@param path [String] absolute path of parent, default root
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME', 'REUSE') defaults 'FAIL'
		#
		# @return [Hash] metadata of created folder
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def create_folder(name, path: nil, exists: 'FAIL')
			fail Errors::ArgumentError, 
				"Invalid argument, must pass name" if Utils.is_blank?(name)
			exists = Constants::EXISTS.fetch(exists.to_sym) { 
				raise Errors::ArgumentError, "Invalid value for exists" }
		
			uri = set_uri_params(Constants::ENDPOINT_FOLDERS, name: path)
			query = { operation: Constants::QUERY_OPS_CREATE }
			form = {name: name, exists: exists}

			response = request('POST', uri: uri, query: query, body: form)
			# @review why this function returns an array of items
			items = response.fetch(:items)
			items.first
		end

		# List folder
		#
		# @param path [String] folder path to list, defults root folder
		# @param depth [Fixnum] levels to recurse, default 0 ie. infinite depth 
		# @param filter [String]
		# @param strict_traverse [Boolean] traversal based on success of filters and possibly the depth parameters, default false
		#
	 	# @return [<Hash>] contains metadata of items under listed folder
		# @raise [Errors::ServiceError Errors::ArgumentError]
		# @todo accept filter array
		def list_folder(path: nil, depth: 0, filter: nil, strict_traverse: false)
			fail Errors::ArgumentError, 
				"Invalid argument must pass strict_traverse of type boolean" unless !!strict_traverse == strict_traverse

			uri = set_uri_params(Constants::ENDPOINT_FOLDERS, name: path)
			query = { depth: depth }

			unless Utils.is_blank?(filter)
				query[:filter] = filter
				query[:'strict-traverse'] = "#{strict_traverse}"
			end

			response = request('GET', uri: uri, query: query)
			# @todo return { meta: [Hash], items: [<Hash>] }
			response.fetch(:items)
		end

		# Delete folder
		#
		# @param path [String] folder path
		# @param commit [Boolean] default false, 
		#		set true to remove folder permanently, else will be moved to trash  
		# @param force [Boolean] default false, set true to delete non-empty folder 
		#
		# @return [Hash] hash with key for success and deleted folder's last version
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def delete_folder(path, commit: false, force: false)
				delete(Constants::ENDPOINT_FOLDERS, path, commit: commit, force: force)
		end

		# Delete file
		#
		# @param path [String] file path
		# @param commit [Boolean] default false, 
		#		set true to remove file permanently, else will be moved to trash  
		#
		# @return [Hash] hash with key for success and deleted file's last version
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def delete_file(path, commit: false)
				delete(Constants::ENDPOINT_FILES, path, commit: commit)
		end

		# Delete private common method for file and folder
		#
		# @param endpoint [String] Bitcasa endpoint for file/folder
		# @param path [String] file/folder path
		# @param commit [Boolean] default false, 
		#		set true to remove file/folder permanently, else will be moved to trash  
		# @param force [Boolean] default false, set true to delete non-empty folder 
		#
		# @return [Hash] hash with key for success and deleted file/folder's last version
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def delete(endpoint, path, commit: false, force: false)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass endpoint" if Utils.is_blank?(endpoint)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass path" if Utils.is_blank?(path)			
			fail Errors::ArgumentError, 
				"Invalid argument must pass commit of type boolean" unless !!commit == commit
			fail Errors::ArgumentError, 
				"Invalid argument must pass force of type boolean" unless !!force == force
			
			uri = set_uri_params(endpoint, name: path)
			query = { commit: "#{commit}" }
			query[:force] = "#{force}" if force == true

			request('DELETE', uri: uri, query: query)
		end
		
		#	Copy folder
		#
		# @param path [String] source folder path
		# @param destination [String] destination folder path
		# @param name [String] name of copied folder
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') 
		#		action to take in case of a conflict with an existing folder, default 'FAIL'
		#
		# @return [Hash] metadata of new folder
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def copy_folder(path, destination, name, exists: 'FAIL')
			copy(Constants::ENDPOINT_FOLDERS, path, destination, name, exists: exists)
		end
		
		#	Copy file
		#
		# @param path [String] source file path
		# @param destination [String] destination folder path
		# @param name [String] name of copied file
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') 
		#		action to take in case of a conflict with an existing file, default 'RENAME'
		#
		# @return [Hash] metadata of new file
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def copy_file(path, destination, name, exists: 'RENAME')
			copy(Constants::ENDPOINT_FILES, path, destination, name, exists: exists)
		end

		#	Copy private common function for folder/file
		#
		# @param endpoint [String] folder/file server endpoint
		# @param path [String] source folder/file path
		# @param destination [String] destination folder path
		# @param name [String] name of copied folder/file, 
		#		default is source folder/file's name
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') 
		#		action to take in case of a conflict with an existing folder/file, default FAIL
		#
		# @return [Hash] metadata of new folder/file
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def copy(endpoint, path, destination, name, exists: 'FAIL')
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(path)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid name" if Utils.is_blank?(name)
		fail Errors::ArgumentError, 
				"Invalid argument, must pass valid destination" if Utils.is_blank?(destination)
			exists = Constants::EXISTS.fetch(exists.to_sym) { 
				raise Errors::ArgumentError, "Invalid value for exists" }
	
			destination = prepend_path_with_forward_slash(destination)
			uri = set_uri_params(endpoint, name: path)
			query = { operation: Constants::QUERY_OPS_COPY }
			form = {to: destination , exists: exists, name: name}

			response = request('POST', uri: uri, query: query, body: form)
			response.fetch(:meta, response)
		end

		#	Move folder
		#
		# @param path [String] source folder path
		# @param destination [String] destination folder path
		# @param name [String] name of moved folder
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') 
		#		action to take in case of a conflict with an existing folder, default 'RENAME'
		#
		# @return [Hash] metadata of moved folder
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def move_folder(path, destination, name, exists: 'FAIL')
			move(Constants::ENDPOINT_FOLDERS, path, destination, name, exists: exists)
		end
	
		#	Move file
		#
		# @param path [String] source file path
		# @param destination [String] destination folder path
		# @param name [String] name of moved file
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') 
		#		action to take in case of a conflict with an existing folder, default 'RENAME'
		#
		# @return [Hash] metadata of moved file
		# @raise Errors::ServiceError, Errors::ArgumentError
		def move_file(path, destination, name, exists: 'RENAME')
			move(Constants::ENDPOINT_FILES, path, destination, name, exists: exists)
		end

		#	Move folder/file private common method
		#
		# @param endpoint [String] file/folder server endpoint
		# @param path [String] source folder/file path
		# @param destination [String] destination folder path
		# @param name [String] name of moved folder/file
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') 
		#		action to take in case of a conflict with an existing folder, default 'FAIL'
		#
		# @return [Hash] metadata of moved folder/file
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		# @review according bitcasa rest docs, path default is root i.e. root is moved!
		def move(endpoint, path, destination, name, exists: 'FAIL')
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(path)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid name" if Utils.is_blank?(name)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid destination" if Utils.is_blank?(destination)
			exists = Constants::EXISTS.fetch(exists.to_sym) { 
				fail Errors::ArgumentError, "Invalid value for exists" }

			uri = set_uri_params(endpoint, name: path)
			query = { operation: Constants::QUERY_OPS_MOVE }
			form = { to: destination, exists: exists, name: name}

			response = request('POST', uri: uri, query: query, body: form)
			response.fetch(:meta, response)
		end
	
		# Get folder meta
		#
		# @param path [String] folder path
		#
		# @return [Hash] metadata of folder
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def get_folder_meta(path)
				get_meta(Constants::ENDPOINT_FOLDERS, path)
		end

		# Get file meta
		#
		# @param path [String] file path
		#
		# @return [Hash] metadata of file
		# @raise Errors::ServiceError, Errors::ArgumentError
		def get_file_meta(path)
				get_meta(Constants::ENDPOINT_FILES, path)
		end
		
		# Get folder/file meta private common method
		#
		# @param endpoint [String] file/folder server endpoint
		# @param path [String] file/folder path
		#
		# @return [Hash] metadata of file/folder
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def get_meta(endpoint, path)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(path)

			uri = set_uri_params(endpoint, name: path, operation: "meta")
			
			response = request('GET', uri: uri)
			response.fetch(:meta, response)
		end

		# Alter folder metadata
		#
		# @param path [String] folder path
		# @param version [String, Fixnum] version number of folder
		# @param version_conflict [String] ('FAIL', 'IGNORE') action to take 
		#		if the version on the client does not match the version on the server
		#
		# @option properties [String] :name (nil) new name
		# @option properties [Fixnum] :date_created (nil) timestamp
		# @option properties [Fixnum] :date_meta_last_modified (nil) timestamp
		# @option properties [Fixnum] :date_content_last_modified (nil) timestamp
		# @option properties [Hash] :application_data({}) will be merged 
		#		with existing application data
		#
		# @return [Hash] updated metadata of folder
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def alter_folder_meta(path, version, version_conflict: 'FAIL', **properties)
			alter_meta(Constants::ENDPOINT_FOLDERS, path, version, 
					version_conflict: version_conflict, **properties)
		end

		# Alter file metadata
		#
		# @param path [String] file path
		# @param version [String, Fixnum] version number of file
		# @param version_conflict [String] ('FAIL', 'IGNORE') action to take 
		#		if the version on the client does not match the version on the server
		#
		# @option properties [String] :name (nil) new name
		# @option properties [Fixnum] :date_created (nil) timestamp
		# @option properties [Fixnum] :date_meta_last_modified (nil) timestamp
		# @option properties [Fixnum] :date_content_last_modified (nil) timestamp
		# @option properties [Hash] :application_data ({}) will be merged 
		#		with existing application data
		#
		# @return [Hash] updated metadata of file
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def alter_file_meta(path, version, version_conflict: 'FAIL', **properties)
			alter_meta(Constants::ENDPOINT_FILES, path, version, 
					version_conflict: version_conflict, **properties)
		end

		# Alter file/folder meta common private method
		#
		# @param endpoint [String] file/folder server endpoint
		# @param path [String] file/folder path
		# @param version [String, Fixnum] version number of file/folder
		# @param version_conflict [String] ('FAIL', 'IGNORE') action to take 
		#		if the version on the client does not match the version on the server
		#
		# @option properties [String] :name (nil) new name
		# @option properties [Fixnum] :date_created (nil) timestamp
		# @option properties [Fixnum] :date_meta_last_modified (nil) timestamp
		# @option properties [Fixnum] :date_content_last_modified (nil) timestamp
		# @option properties [Hash] :application_data ({}) will be merged 
		#		with existing application data
		#
		# @return [Hash] updated metadata of file/folder
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def alter_meta(endpoint, path, version, version_conflict: 'FAIL', **properties)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass path" if Utils.is_blank?(path)
			
			version_conflict = 
			Constants::VERSION_CONFLICT.fetch(version_conflict.to_sym) {
			 		fail Errors::ArgumentError, "Invalid value for version-conflict" }
			uri = set_uri_params(endpoint, name: path, operation: "meta")
			
			req_properties = {}
			req_properties = properties.dup unless properties.empty?
			application_data = req_properties[:application_data]
			# @review suppress multi_json exception and continue or fail
			req_properties[:application_data] = 
				Utils.hash_to_json(application_data) unless Utils.is_blank?(application_data)
			req_properties[:'version'] = "#{version}"
			req_properties[:'version-conflict'] = version_conflict

			response = request('POST', uri: uri, body: req_properties)
			response.fetch(:meta, response)
		end

		# Upload file
		#			file pointer points to eof after upload is completed
		# @param path [String] path to upload file to 
		# @param file [::File] opened file
		# @param name [String] name of uploaded file, default basename of filepath
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME', 'REUSE') 
		#		action to take if the filename of the file being uploaded conflicts 
		#		with an existing file
		#
		# @return [Hash] metadata of uploaded file
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		# @example:
		# 		::File.open("/tmp/xyz", "r") do |file|
		#				client.upload("pathid", file, name: 'testfile')
		#				file.rewind
		#			end
		# @todo reuse fallback and reuse attributes
		# @review should file#rewind be called at end of this function
		def upload(path, file, name: nil, exists: 'FAIL')
			fail Errors::ArgumentError, 
				"Invalid argument, must pass path" if Utils.is_blank?(path)
			exists = Constants::EXISTS.fetch(exists.to_sym) { 
				fail Errors::ArgumentError, "Invalid value for exists" }
			fail Errors::ArgumentError, 
				"Invalid argument, must pass ::File type object" unless(file.kind_of?(::File))

			uri = set_uri_params(Constants::ENDPOINT_FILES, name: path) 
			form = {file: file, exists: exists}
			form[:name] = name unless Utils.is_blank?(name)
			
			headers = {
				Constants::HEADER_CONTENT_TYPE => 
					Constants::CONTENT_TYPE_MULTI 
			}	

			request('POST', uri: uri, header: headers,	body: form)
		end

		# Download file
		#
		# @param path [String] file path to download
		# @param startbyte [Fixnum] starting byte (offset) in file
		# @param bytecount [Fixnum] number of bytes to dowload
		#
		# @yield [String] chunk of data as soon as available, 
		#		chunksize size may vary each time
		# @return [String] file data is returned if no block given
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def download(path, startbyte: 0, bytecount: 0, &block)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass path" if Utils.is_blank?(path)
			fail Errros::ArgumentError, 
				"Size must be positive" if (bytecount < 0 || startbyte < 0)

			uri = set_uri_params(Constants::ENDPOINT_FILES, name: path) 
			header = Constants::HEADER_CONTENT_TYPE_APP_URLENCODED.dup
			
			unless startbyte == 0 && bytecount == 0
				if bytecount == 0
					header[:Range] = "bytes=#{startbyte}-"
				else
					header[:Range] = "bytes=#{startbyte}-#{startbyte + bytecount - 1}"
				end
			end

			request('GET', uri: uri, header: header, &block)
		end

		# List single version of file
		#
		# @param path [String] file path
		# @param version [Fixnum] desired version of the file referenced by path
		#
		# @return [<Hash>] hashes representing metatdata passed version of file
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		# @review Bitcasa Server returns unspecified error 9999 
		#		if current version of file is passed, works for pervious file versions.
		def list_single_file_version(path, version)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(path)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" unless version.is_a?(Fixnum)
			
			uri = set_uri_params(Constants::ENDPOINT_FILES, name: path, 
					operation: "versions/#{version}")

			request('GET', uri: uri, 
					header:  Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
		end
	
		# Promote file version
		#
		# @param path [String] file path
		# @param version [Fixnum] version of file specified by path
		#
		# @return [Hash] metadata of promoted file
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def promote_file_version(path, version)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(path)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid version" unless version.is_a?(Fixnum)
			
			uri = set_uri_params(Constants::ENDPOINT_FILES, name: path, 
					operation: "versions/#{version}")
			query = { operation: Constants::QUERY_OPS_PROMOTE }
			
			request('POST', uri: uri, query: query)
		end

		# List versions of file
		#
		# @param path [String] file path
		# @param start_version [Fixnum] version number to begin listing file versions
		# @param stop_version [Fixnum] version number from which to stop 
		#		listing file versions
		# @param limit [Fixnum] how many versions to list in the result set. 
		#		It can be negative.
		#
		# @return [<Hash>] hashes representing metadata for selected versions 
		#		of the file as recorded in the History
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		# @review Returns empty items array if file has no more than current version
		def list_file_versions(path, start_version: 0, stop_version: -1, limit: 10)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(path)
			
			uri = set_uri_params(Constants::ENDPOINT_FILES, name: path, 
					operation: "versions")

			query = {
				:'start-version' => start_version, :'limit' => limit
			}
			query[:'stop-version'] = stop_version if stop_version > 0
			
			request('GET', uri: uri, query: query,
					header: Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
		end
	
		# Create share
		#
		# @param paths [Array<String>] array of file/folder paths
		#
		# @return [Hash] metadata of share
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def create_share(paths)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid list of paths" if Utils.is_blank?(paths)
		
			body = Array(paths).map{ |path|
				path = prepend_path_with_forward_slash(path)
				"path=#{Utils.urlencode(path)}"}.join("&")
			
			uri = { endpoint: Constants::ENDPOINT_SHARES }
			
			request('POST', uri: uri, body: body)
		end

		# Delete share
		#
		# @param share_key [String] id of the share to be deleted
		#
		# @return [Hash] hash containing success string
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def delete_share(share_key)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid share key" if Utils.is_blank?(share_key)

			uri = set_uri_params(Constants::ENDPOINT_SHARES, name: "#{share_key}/")

			request('DELETE', uri: uri,
					header:  Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
		end
	
		# List a share	
		#
		# @param share_key [String] id of the share
		# @param path [String] path of item in share to list
		#
		# @return [<Hash>] hashes representing metatdata of each item in share
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def browse_share(share_key, path: nil)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(share_key)
			
			uri = set_uri_params(Constants::ENDPOINT_SHARES, 
					name: "#{share_key}#{path}", operation: "meta")

			response = request('GET', uri: uri,
					header:  Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
			# @review if target item in share is file, does it return meta instead of items
			response.fetch(:items)
		end
	
		# List user's shares
		#
		# @return [<Hash>] hashes representing metatdata of user's shares
		# @raise [Errors::ServiceError]
		def list_shares
			uri = { endpoint: Constants::ENDPOINT_SHARES }
			
			request('GET', uri: uri,
					header: Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
		end

		# Add contents of share to user's filesystem
		#
		# @param share_key [String] id of the share
		# @param path [String] path in user's account to receive share at,
		#		default is "/" root
		# @param exists [String] ('RENAME', 'FAIL', 'OVERWRITE'], default is 'RENAME'
		#
		# @return [<Hash>] hashs representing metadata of items in share
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def receive_share(share_key, path: nil, exists: 'RENAME')
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid share key" if Utils.is_blank?(share_key)
			exists = Constants::EXISTS.fetch(exists.to_sym) { 
				fail Errors::ArgumentError, "Invalid value for exists" }

			uri = set_uri_params(Constants::ENDPOINT_SHARES, name: "#{share_key}/")
			form = { exists: exists }
			form[:path] = path unless Utils.is_blank?(path)

			request('POST', uri: uri, body: form)
		end
			
		# Unlock share
		#
		# @param share_key [String] id of the share
		# @param password [String] password of share
		#
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def unlock_share(share_key, password)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(share_key)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(password)
			
			uri = set_uri_params(Constants::ENDPOINT_SHARES, name: share_key, 
					operation: "unlock")
			form = { password: password }
			
			request('POST', uri: uri, body: form)
		end
		
		# Alter share info
		# 	Changes, adds, or removes the share’s password or updates the name
		#
		# @param share_key [String] id of the share whose attributes are to be changed
		#
		# @param current_password [String] current password of the share
		# @param password [String] new password of share
		# @param name [String] new name of share
		#
		# @return [Hash] metadata of share
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def alter_share_info(share_key, current_password: nil, 
				password: nil, name: nil)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(share_key)
			
			uri = set_uri_params(Constants::ENDPOINT_SHARES, name: share_key, 
					operation: "info")
			form = {}
			form[:current_password] = current_password unless Utils.is_blank?(current_password)
			form[:password] = password unless Utils.is_blank?(password)
			form[:name] = name unless Utils.is_blank?(name)

			request('POST', uri: uri, body: form)
		end

		# List history
		# 	lists cloudfs actions history
		#
		# @param start [Fixnum] version number to start listing historical actions from, 
		#		default -10. It can be negative in order to get most recent actions.
		# @param stop [Fixnum] version number to stop listing historical actions from (non-inclusive)
		#
		# @return [<Hash>] containing history items
		# @raise [Errors::ServiceError]
		def list_history(start: -10, stop: 0)
			uri = { endpoint: Constants::ENDPOINT_HISTORY }
			query = { start: start }
			query[:stop] = stop unless stop == 0
			
			request('GET', uri: uri, query: query,
					header:  Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
		end

		# Browse trash
		#
		# @param path [String] path to location in user's trash, defaults to root of trash
		#
		# @return [Hash] containes metadata of browsed trash item 
		#		and array of hashes representing list of items under browsed item if folder -
		#		 { :meta => Hash, :items => <Hash> }
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def browse_trash(path: nil)
			uri = set_uri_params(Constants::ENDPOINT_TRASH, name: path)
			
			response = request('GET', uri: uri,
					header:  Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
		
			meta = response.fetch(:meta, response)
			items = response.fetch(:items, [])
			{ meta: meta, items: items }
		end

		# Delete trash item
		#
		# @param path [String] path to location in user's trash, 
		#		default all trash items are deleted
		#
		# @return [Hash] containing success: true
		# @raise [Errors::ServiceError]
		# @review Bitcasa Server returns Unspecified Error 9999 if no path provided, 
		#		expected behaviour is to delete all items in trash
		def delete_trash_item(path: nil)
			uri = set_uri_params(Constants::ENDPOINT_TRASH, name: path)
			
			request('DELETE', uri: uri, 
					header:  Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
		end

		# Recover trash item
		#
		# @param path [String] path to location in user's trash
		#
		# @param restore [String] ('FAIL', 'RESCUE', 'RECREATE') action to take 
		#		if recovery operation encounters issues
		# @param destination [String] rescue (default root) or recreate(named path) 
		#		path depending on exists option to place item into if the original 
		#		path does not exist
		#
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def recover_trash_item(path, restore: 'FAIL', destination: nil)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(path)
			restore = Constants::RESTORE.fetch(restore.to_sym) { 
				fail Errors::ArgumentError, "Invalid value for restore" }
			
			uri = set_uri_params(Constants::ENDPOINT_TRASH, name: path)
			
			form = { :'restore' => restore }
			if restore == Constants::RESTORE[:RESCUE]
				unless Utils.is_blank?(destination)
					destination = prepend_path_with_forward_slash(destination)
					form[:'rescue-path'] = destination
				end
			elsif restore == Constants::RESTORE[:RECREATE]
					unless Utils.is_blank?(destination)
					destination = prepend_path_with_forward_slash(destination)
					form[:'recreate-path'] = destination
					end
			end
				
			request('POST', uri: uri, body: form)
		end

		# Request common method to send http request to bitcasa service
		#
		# @param method [String, Symbol] ('GET', 'POST', 'DELETE') http verb
		#
		# @param uri [Hash] containing endpoint and name that is endpoint suffix
		#		uri: { :endpoint => "/v2/folders", :name => "{ path }/meta" }
		# @param header [Hash] containing key:value pairs for request header
		# @param query [Hash] containing key:value pairs of query
		# @param body [Hash, String] containing key:value pairs for post forms-
		#		body: { :grant_type => "password", :password => "xyz" },
		#		body: { :file => (File,StringIO), :name => "name" }
		#		body: "path=pathid&path=pathdid&path=pathid"
		#
		# @return [Hash, String] containing result from bitcasa sevice or file data
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def request(method, uri: {}, header: {}, query: {}, body: {}, &block)
			header = {
				Constants::HEADER_AUTHORIZATION => "Bearer #{@access_token}"
			}.merge(header)
				
			unless (uri[:endpoint] == Constants::ENDPOINT_OAUTH ||
						uri[:endpoint] == Constants::ENDPOINT_CUSTOMERS) 
				fail Errors::SessionNotLinked, 
					"access token is not set, please authenticate" if Utils.is_blank?(
							@access_token)
			end

			url = create_url(@host, endpoint: uri[:endpoint], name: uri[:name])
			body = set_multipart_upload_body(body)
			response = @http_connection.request(method, url, query: query, 
						header: header, body: body, &block)
			parse_response(response)
			rescue Errors::ServerError
					Errors::raise_service_error($!)
		end
		
		# Set multipart body for file upload
		# @param body [Hash]
		# @return [<Hash>] mutipart upload forms
		def set_multipart_upload_body(body={})
			return body unless body.is_a?(Hash) && body.key?(:file)

			file = body[:file]
			exists = body[:exists]	
			
			if Utils.is_blank?(body[:name])
				path = file.respond_to?(:path) ? file.path : nil
				filename = (::File.basename(path) || '')
			else
				filename = body[:name]
			end

			multipart_body = []
			multipart_body << { 'Content-Disposition' => 'form-data; name="exists"', 
							:content => exists } if exists
			multipart_body << {'Content-Disposition' => 
						"form-data; name=\"file\"; filename=\"#{filename}\"", 
						"Content-Type" => "application/octet-stream", 
							:content => file }
			multipart_body
		end

		# Create url
		#		appends endpoint and name prefix to host
		#
		#	@param host [String] server address
		#	@param endpoint [String] server endpoint
		# @param name [String] name prefix
		#
		# @return [String] url
		def create_url(host, endpoint: nil, name: nil)
			url = "#{host}#{endpoint}#{name}"
		end

		# Create response
		#		parses bitcasa service response into hash
		#
		# @param response [Hash]
		#		@see Bitcasa::Client::Connection#request
		#
		# @return [Hash] response from bitcasa service
		def parse_response(response)
			if response[:content_type] && 
				response[:content_type].include?("application/json")

				resp = Utils.json_to_hash(response.fetch(:content))
				resp.fetch(:result, resp)
			else
		 		response.fetch(:content) 			
			end	
		end

		# Prepend path with '/'
		#
		# @param [String, nil] path
		#
		# @return [String] path
		def prepend_path_with_forward_slash(path)
			if Utils.is_blank?(path)
					path = "/"
			elsif path[0] != '/'
				path = "#{path}".insert(0, '/')
			end
			path
		end
		
		# Set uri params
		#
		# @param endpoint [String] server endpoint
		# @param name [String] path prefix
		# @param operation [String] path prefix 
		#
		# @return [Hash] uri { :endpoint => "/v2/xyz", :name => "/abc/meta" }
		# @optimize clean this method
		def set_uri_params(endpoint, name: nil, operation: nil)
			uri = { endpoint: endpoint }
			# @review removing new line and spaces from end and begining of name
			unless Utils.is_blank?(name)
				name = name.strip
				delim ||=	'/' unless name[-1] == '/'
			end
			# append to name with delim if operation is given
			name = "#{name.to_s}" << "#{delim}#{operation}" unless Utils.is_blank?(operation)
			unless Utils.is_blank?(name)
				if endpoint.to_s[-1] == '/' && name[0] == '/'
					# remove leading / from name if endpoint has traling /
					name = name[1..-1]
				elsif endpoint.to_s[-1] != '/' && name.to_s[0] != '/'
					# insert leading / to name
					name =  "#{name}".insert(0, '/')
				end
				uri[:name] = name
			end
			uri
		end	 

		private :delete, :copy, :move, :get_meta, :alter_meta, :request,
		 :set_multipart_upload_body, :parse_response, :create_url, 
		 :prepend_path_with_forward_slash, :set_uri_params

	end
end
