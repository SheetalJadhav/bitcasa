require_relative './client/connection.rb'
require_relative './client/constants.rb'
require_relative './client/utils.rb'
require_relative './client/error.rb'

module Bitcasa

# TODO: Support async requests, blocker methods like wait for async operations,
#		streaming upload i.e. chunked upload(not sure if server supports), 
#		file stream upload, exists: reuse attribute handling,
#		streaming download, download to file stream,
#		HTTP wire tap, Progress listener
#		optional string arguments should be default nil instead of ""
#	OPTIMIZE: move all functions File, Folder, Share, Trash, Authenticate, Account, User, History, request, response mrduleponding  under ./client folder, this file should contain wrapper function only as it is getting too messy with so many methods one file.
# OPTIMIZE: Automate api arguments validation

	# Bitcasa::Client class provides low level api access to bitcasa cloud
	# All api's requests accept native type of request arguments 
	#		i.e. String, Fixnum, hash etc. and responds with hash, boolean or nil. 
	# Any error server, client, invalid argument raises corresponding Exception
	#		child of Bitcasa::Client::Error class
	# Usage: one instance for all calls per server for performance.
	# Example:
	#		client = Bitcasa::Client.new(clientid, secret, host)
	#		client.method(required,.. , key: default, .. ,optional)
	class Client
	
		# Bitcasa::Client::BCFile class extends global File class with attribute name that is returned
		#				by File path method.
		# HACK: HTTPClient gem uploads file with basename of opened File object
		# In order to upload file with optional name of uploaded file, this hack is required
		class BCFile < ::File
			attr_accessor :name
				# Define path
				def path
					@name
				end				
		end

		attr_reader :clientid, :secret, :host, :access_token, :linked
		attr_reader :http_connection

		# Creates MT safe Client instance that manages rest api calls to Bitcasa Cloud
		# @param clientid [String] application clientid
		# @param secret [String] application secret
		# @param host [String] server address
		# @return Client class instance
		def initialize(clientid, secret, host)
			@clientid = "#{clientid}"
			@secret = "#{secret}"
			if 0 == (/https:\/\// =~ host)
					@host = "#{host}"
			else @host = "https://#{host}"
			end	
			@access_token = nil
			@http_connection = Connection.new
		end

		# Checks if Client can make authenticated requests to Bitcasa
		# @return true/false
		def is_linked
			unless Utils::is_blank?(@access_token)
				ping
				@linked = true
			else @linked = false
			end
			rescue Bitcasa::Error
				@linked = false
		end
		
		# Sets Client access token to nil
		def unlink
			@access_token = nil
			# REVIEW: consider requests in context of Client
			@linked = false
			nil	
		end
		
		# Authenticate Obtains an OAuth2 access token that authenticates an end-user for a particular client 
		# @param username [String] username of the user
		# @param password [String] password of the user
    	# @return true
		# @raise Bitcasa::Client::Error
		def authenticate(username, password)
			raise InvalidArgumentError, "Invalid argument, must pass username" if Utils::is_blank?(username)
			raise InvalidArgumentError, "Invalid argument, must pass password" if Utils::is_blank?(password)

			date = Time.now.strftime("#{Constants::DATE_FORMAT}")
			form = {
				"#{Constants::PARAM_GRANT_TYPE}"=>"password", 
				"#{Constants::PARAM_PASSWORD}"=>"#{password}", 
				"#{Constants::PARAM_USER}"=>"#{username}"
			}
		
			headers = {
				"#{Constants::HEADER_CONTENT_TYPE}"=>
				"#{Constants::CONTENT_TYPE_APP_URLENCODED}", 
				"#{Constants::HEADER_DATE}"=>"#{date}"
			}	

			endpoint = "#{Constants::ENDPOINT_OAUTH}"
			uri = {
					endpoint: 	"#{endpoint}" 
			}
			
			signature = Utils::generate_auth_signature(endpoint, 
														form, headers, @secret)
			headers["#{Constants::HEADER_AUTHORIZATION}"] = "BCS #{@clientid}:#{signature}"
			
			access_info = request({
					method: 'POST', 
					uri: uri, 
				 	header: headers,	
					body: form
				})
			@access_token = access_info.fetch(:access_token)
			true
		end

		# Ping bitcasa server to verifies the end-user’s access token
		# @raise Bitcasa::Client::Error
		def ping
			request({
					method: 'GET', 
					uri: {endpoint: "#{Constants::ENDPOINT_PING}"}, 
				 	header: Constants::HEADER_CONTENT_TYPE_APP_URLENCODED.dup
				})
			nil
		end

		# Creates a new end-user account for a Paid CloudFS
		# @param username [String] username of the end-user.
		# @param password [String] password of the end-user.
		# @option email [String] email of the end-user
		# @option first_name [String] first name of end user
		# @option last_name [String] last name of end user
		# @return hash containing user's profile information
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def create_account(username, password, email: nil, first_name: nil, last_name: nil)
			raise InvalidArgumentError, "Invalid argument, must pass username" if Utils::is_blank?(username)
			raise InvalidArgumentError, "Invalid argument, must pass password" if Utils::is_blank?(password)

			date = Time.now.strftime("#{Constants::DATE_FORMAT}")
			form = {
				"#{Constants::PARAM_GRANT_TYPE}"=>"password", 
				"#{Constants::PARAM_PASSWORD}"=>"#{password}", 
				"#{Constants::PARAM_USER}"=>"#{username}"
			}
	
			unless Utils.is_blank?(email)
				form[:email] = "#{email}"
			end
			unless Utils.is_blank?(first_name)
				form[:first_name] = "#{first_name}"
			end
			unless Utils.is_blank?(last_name)
				form[:last_name] = "#{last_name}"
			end

			headers = {
				"#{Constants::HEADER_CONTENT_TYPE}"=>
				"#{Constants::CONTENT_TYPE_APP_URLENCODED}", 
				"#{Constants::HEADER_DATE}"=>"#{date}"
			}	
			endpoint = "#{Constants::ENDPOINT_CUSTOMERS}"
			uri = {
					endpoint: "#{endpoint}" 
			}
			
			signature = Utils::generate_auth_signature(endpoint, 
														form, headers, @secret)
			headers["#{Constants::HEADER_AUTHORIZATION}"] = "BCS #{@clientid}:#{signature}"
			
			request({
					method: 'POST', 
					uri: uri, 
				 	header: headers,	
					body: form
				})
		end	

		# Get bitcasa user profile information
		# @return hash containing user information
		# @raise Bitcasa::Client::Error
		def get_profile
			uri = {
				endpoint: "#{Constants::ENDPOINT_USER_PROFILE}"
			}
			
			request({
					method: 'GET', 
					uri: uri,
				 	header: Constants::HEADER_CONTENT_TYPE_APP_URLENCODED.dup
			})
		end

		# Create folder
		#	@param path [String] absolute path of parent
		# @param name [Sting] name of folder to create
		# @option exists ["FAIL"|"OVERWRITE"|"RENAME"|"REUSE"] defaults "FAIL"
		# @return hash containing metadata of created folder
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		# TODO: make path optional parameter, default root
		def create_folder(path, name, exists: 'FAIL')
			raise InvalidArgumentError, "Invalid argument, must pass path" if Utils::is_blank?(path)
			raise InvalidArgumentError, "Invalid argument, must pass name" if Utils::is_blank?(name)
			exists = Constants::EXISTS[exists.to_sym] or raise InvalidArgumentError, "Invalid value for exists"
			
			path.insert(0, '/') unless (path[0] == '/')
			
			uri = {endpoint: "#{Constants::ENDPOINT_FOLDERS}", 
					name: "#{path}"}

			query = {operation: "#{Constants::QUERY_OPS_CREATE}"}
			form = {name: "#{name}", exists: "#{exists}"}

			response = request({
					method: 'POST', 
					uri: uri, 
					query: query, 
					body: form
			})
			items = response[:items]
			items.first
		end

		# List folder
		# @option path [String] folder path to list, defults "/"
		# @option depth [Fixnum] levels to recurse, default 0 ie. infinite depth 
		# @option filter [String] id!=xyz
		# @option strict_traverse [Boolean] traversal based on success of filters and possibly the depth parameters, default false
	 	# @return array of hashes, each entry contains metadata of an item under listed folder
		# @raise Bitcasa::Client::Error
		# TODO: accept filter array
		def list_folder(path: "/", depth: 0, filter: nil, strict_traverse: false)
			
			path = add_root_to_path(path)
			# TODO: don't initialize
			query = {}
			uri = {
				endpoint: "#{Constants::ENDPOINT_FOLDERS}", 
				name: "#{path}"
			}
			query = {depth: depth}

			unless Utils::is_blank?(filter)
				query[:filter] = "#{filter}"
				query[:'strict-traverse'] = "#{strict_traverse}"
			end

			response = request({
					method: 'GET', 
					uri: uri, 
					query: query, 
			})
			# TODO: dont fetch just set
			response.fetch(:items)
		end

		# Delete folder
		# @param path [String] folder path to delete
		# @option commit [Boolean] default false, set true to remove folder permanently, else will be moved to trash  
		# @option force [Boolean] default false, set true to delete non-empty folder 
		# @return hash with key for success and deleted folder's last version
		# @raise Bitcasa::Client::Error, Bitcasa::Client:InvalidArgumentError
		def delete_folder(path, commit: false, force: false)
				delete(Constants::ENDPOINT_FOLDERS, path, commit: commit, force: force)
		end

		# Delete file	
		# @param path [String] folder path to delete
		# @option commit [Boolean] default false, set true to remove file permanently, else will be moved to trash  
		# @return hash with key for success and deleted file's last version
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def delete_file(path, commit: false)
				delete(Constants::ENDPOINT_FILES, path, commit: commit)
		end

		# Delete private common method for file and folder
		# @param endpoint [String] Bitcasa endpoint for file/folder
		# @param path [String] file/folder path to list
		# @option commit [Boolean] default false, set true to remove file/folder permanently, else will be moved to trash  
		# @option force [Boolean] default false, set true to delete non-empty folder 
		# @return hash with key for success and deleted file/folder's last version
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def delete(endpoint, path, commit: false, force: false)
			raise InvalidArgumentError, "Invalid argument, must pass endpoint" if Utils::is_blank?(endpoint)
			raise InvalidArgumentError, "Invalid argument, must pass path" if Utils::is_blank?(path)			
			raise InvalidArgumentError, "Invalid argument must pass commit of type boolean" unless !!commit == commit
			raise InvalidArgumentError, "Invalid argument must pass force of type boolean" unless !!force == force
			
			path.insert(0, '/') unless (path[0] == '/')
			uri = {
				endpoint: "#{endpoint}", 
				name: "#{path}"
			}
			query = {commit: "#{commit}"}
			if force == true
				query[:force] = "#{force}"
			end

			request({
					method: 'DELETE', 
					uri: uri, 
					query: query 
			})
		end
		
		#	Copy folder
		# @param path [String] source folder path
		# @param destination [String] destination folder path
		# @option name [String] name of copied folder, default is source folder's name
		# @option exists ["FAIL"|"OVERWRITE"|"RENAME"] action to take in case of a conflict with an existing folder, default FAIL
		# @return hash containing metadata of new folder
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def copy_folder(path, destination, name: "", exists: 'FAIL')
			copy(Constants::ENDPOINT_FOLDERS, path, destination, name: name, exists: exists)
		end
		
		#	Copy file
		# @param path [String] source file path
		# @param destination [String] destination folder path
		# @option name [String] name of copied file, defualt name is source file's name
		# @option exists ["FAIL"|"OVERWRITE"|"RENAME"] action to take in case of a conflict with an existing file, default RENAME
		# @return hash containing metadata of new file
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def copy_file(path, destination, name: "", exists: 'RENAME')
			copy(Constants::ENDPOINT_FILES, path, destination, name: name, exists: exists)
		end

		#	Copy private common function for folder/file
		# @param endpoint [String] folder/file server endpoint
		# @param path [String] source folder/file path
		# @param destination [String] destination folder path
		# @option name [String] name of copied folder/file, default is source folder/file's name
		# @option exists ["FAIL"|"OVERWRITE"|"RENAME"] action to take in case of a conflict with an existing folder/file, default FAIL
		# @return hash containing metadata of new folder/file
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def copy(endpoint, path, destination, name: "", exists: 'FAIL')
			raise InvalidArgumentError, "Invalid argument, must pass valid path" if Utils::is_blank?(path)
			raise InvalidArgumentError, "Invalid argument, must pass valid destination" if Utils::is_blank?(destination)
			exists = Constants::EXISTS[exists.to_sym] or raise InvalidArgumentError, "Invalid value for exists"
	
			path.insert(0, '/') unless (path[0] == '/')
			destination.insert(0, '/') unless (destination[0] == '/')
			
			uri = {
				endpoint: "#{endpoint}", 
				name: "#{path}"
			}
			
			query = {operation: "#{Constants::QUERY_OPS_COPY}"}
			
			form = {to: "#{destination}", exists: "#{exists}"}
			unless Utils::is_blank?(name)
				form[:name] = "#{name}"
			end
			response = request({
					method: 'POST', 
					uri: uri, 
					query: query,
				 	body: form	
			})
			response.key?(:meta) ? response[:meta] : response
		end

		#	Move folder
		# @param path [String] source folder path
		# @param destination [String] destination folder path
		# @param name [String] name of moved folder
		# @option exists ["FAIL"|"OVERWRITE"|"RENAME"] action to take in case of a conflict with an existing folder, default "FAIL"
		# @return hash containing metadata of new folder
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		# OPTIMIZE: make name parameter optional, source folder's name should be default
		def move_folder(path, destination, name, exists: 'FAIL')
			move(Constants::ENDPOINT_FOLDERS, path, destination, name, exists: exists)
		end
	
		#	Move file
		# @param path [String] source file path
		# @param destination [String] destination folder path
		# @param name [String] name of moved file
		# @option exists ["FAIL"|"OVERWRITE"|"RENAME"] action to take in case of a conflict with an existing file, default "RENAME"
		# @return hash containing metadata of new file
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		# OPTIMIZE: make name parameter optional, source file's name should be default
		def move_file(path, destination, name, exists: 'RENAME')
			move(Constants::ENDPOINT_FILES, path, destination, name, exists: exists)
		end

		#	Move folder/file private common function
		# @param endpoint [String] file/folder server endpoint
		# @param path [String] source folder/file path
		# @param destination [String] destination folder path
		# @param name [String] name of moved folder/file
		# @option exists ["FAIL"|"OVERWRITE"|"RENAME"] action to take in case of a conflict with an existing folder, default "FAIL"
		# @return hash containing metadata of new folder/file
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def move(endpoint, path, destination, name, exists: 'FAIL')
			raise InvalidArgumentError, "Invalid argument, must pass valid path" if Utils::is_blank?(path)
			raise InvalidArgumentError, "Invalid argument, must pass valid name" if Utils::is_blank?(name)
			raise InvalidArgumentError, "Invalid argument, must pass valid destination" if Utils::is_blank?(destination)
			exists = Constants::EXISTS[exists.to_sym] or raise InvalidArgumentError, "Invalid value for exists"

			path.insert(0, '/') unless (path[0] == '/')
			uri = {
				endpoint: "#{endpoint}", 
				name: "#{path}"
			}
			query = {operation: "#{Constants::QUERY_OPS_MOVE}"}
			
			form = {to: "#{destination}", exists: "#{exists}", name: "#{name}"}
			response = request({
					method: 'POST', 
					uri: uri, 
					query: query,
				 	body: form	
			})
			response.key?(:meta) ? response[:meta] : response
		end
	
		# Get folder meta
		# @param path [String] folder path
		# @return hash containing metadata of new folder
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def get_folder_meta(path)
				get_meta(Constants::ENDPOINT_FOLDERS, path)
		end

		# Get file meta
		# @param path [String] file path
		# @return hash containing metadata of new file
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def get_file_meta(path)
				get_meta(Constants::ENDPOINT_FILES, path)
		end
		
		# Get folder/file meta private common method
		# @param endpoint [String] file/folder server endpoint
		# @param path [String] file/folder path
		# @return hash containing metadata of new file/folder
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def get_meta(endpoint, path)
			raise InvalidArgumentError, "Invalid argument, must pass valid path" if Utils::is_blank?(path)
			path.insert(0, '/') unless (path[0] == '/')

			uri = {
				endpoint: "#{endpoint}", 
				name: "#{path}/meta"
			}
			response = request({
					method: 'GET', 
					uri: uri, 
			})
			response.key?(:meta) ? response[:meta] : response
		end

		#	Alter folder meta
		# @param path [String] folder path
		# @param version [Fixnum] version number of folder
		# @param version_conflict ["FAIL"|"IGNORE"] action to take if the version on the client does not match the version on the server
		# @option name [String] new name of the folder
		# @option date_created [Fixnum] new date_created for folder
		# @option date_meta_last_modified [Fixnum] new date_meta_last_modified for folder
		# @option date_content_last_modified [Fixnum] new date_content_last_modified for folder
		# @option application_data [Hash] dictionary of objects to merge into the folder’s existing application_data
		# @return hash containing updated metadata of folder
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def alter_folder_meta(path, version, version_conflict: 'FAIL', **properties)
			alter_meta(Constants::ENDPOINT_FOLDERS, path, version, version_conflict: version_conflict, **properties)
		end

		#  Altering version of file alter_file_meta
		# @param path [String] file path
		# @param version [Fixnum] version number of file
		# @option version_conflict ["FAIL"|"IGNORE"] action to take if the version on the client does not match the version on the server
		# @option name [String] new name of the file
		# @option date_created [Fixnum] new date_created for file
		# @option date_meta_last_modified [Fixnum] new date_meta_last_modified for file
		# @option date_content_last_modified [Fixnum] new date_content_last_modified for file
		# @option application_data [Hash]
		# @return hash containing updated metadata of file
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		
		def alter_file_meta(path, version, version_conflict: 'FAIL', **properties)
			alter_meta(Constants::ENDPOINT_FILES, path, version, version_conflict: version_conflict, **properties)
		end

		# Alter file/folder meta common private method
		# @param path [String] file/folder path
		# @param version [Fixnum] version number of file/folder
		# @param version_conflict ["FAIL"|"IGNORE"] action to take if the version on the client does not match the version on the server
		# @option name [String] new name
		# @option date_created [Fixnum] new date_created
		# @option date_meta_last_modified [Fixnum] new date_meta_last_modified
		# @option date_content_last_modified [Fixnum] new date_content_last_modified
		# @option application_data [Hash]
		# @return hash containing updated metadata of file/folder
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def alter_meta(endpoint, path, version, version_conflict: "fail", **properties)
			raise InvalidArgumentError, "Invalid argument, must pass path" if Utils::is_blank?(path)
			version_conflict = Constants::VERSION_CONFLICT[version_conflict.to_sym] or raise InvalidArgumentError, "Invalid value for version-conflict"

			path.insert(0, '/') unless (path[0] == '/')
			#	TODO: no need to merge, set directly	
			req_properties = {
				:'name' => "",
				:'date_created' => "",
				:'date_meta_last_modified' => "",
				:'date_content_last_modified' => "",
				:'mime' => "",
				:'extension' => "",
				:'application_data' => {}
			}.merge(properties)

			unless (req_properties[:application_data]).empty?
					# REVIEW: rescue exception raised by multi json and set nil application data
					#			or let it raise the exception ?
					req_properties[:application_data] = Utils::hash_to_json(req_properties[:application_data])
			end
			
			req_properties.delete_if{ |k,v| 
				Utils::is_blank?(v)
			}
			req_properties[:'version'] = "#{version}"
			req_properties[:'version-conflict'] = "#{version_conflict}"

			uri = {endpoint: endpoint, 
					name: "#{path}/meta"}
			
			form = req_properties
			response = request({
					method: 'POST', 
					uri: uri, 
					body: form
			})
			response.key?(:meta) ? response[:meta] : response
		end

		# Upload file
		# @param path [String] path to upload file to 
		# @param filepath [String] absolute path of local file to upload
		# @option name [String] name of uploaded file, default basename of filepath
		# @option exists ["FAIL"|"OVERWRITE"|"RENAME"|"REUSE"] action to take if the filename of the file being uploaded conflicts with an existing file
		# @return hash containing metadata of uploaded file
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		# TODO exists: reuse handling of reuse-attributes and reuse-fallback
		# OPTIMIZE streaming upload i.e. chunked upload(not sure if server supports), file Stream upload, provide option file [File] instead of filepat
		def upload(path, filepath, name: "", exists: 'FAIL')
			raise InvalidArgumentError, "Invalid argument, must pass path" if Utils::is_blank?(path)
			raise InvalidArgumentError, "Invalid argument, must pass local filepath" if Utils::is_blank?(filepath) or !::File.file?("#{filepath}")
			exists = Constants::EXISTS[exists.to_sym] or raise InvalidArgumentError, "Invalid value for exists"

			path.insert(0, '/') unless (path[0] == '/')
			
			uri = {endpoint: "#{Constants::ENDPOINT_FILES}", 
					name: "#{path}"}
			
			form = {filepath: "#{filepath}", exists: exists}
			unless Utils::is_blank?(name)
				form[:name] = name
			end

			headers = {
				"#{Constants::HEADER_CONTENT_TYPE}"=>
				"#{Constants::CONTENT_TYPE_MULTI}"
			}	

			request({
					method: 'POST', 
					uri: uri,
				 	header: headers,	
					body: form
			})
		end

		# Download file
		# @param path [String] file path to download
		# @param startbyte [Fixnum] starting byte (offset) in file
		# @param bytecount [Fixnum] number of bytes to dowload
		# @yield block |data|
		# @return if no block then file data buffer is returned
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		# OPTIMIZE support response stream, currently immitated by yielding response to block
		def download(path, startbyte: 0, bytecount: 0, &block)
			raise InvalidArgumentError, "Invalid argument, must pass path" if Utils::is_blank?(path)

			path.insert(0, '/') unless (path[0] == '/')
			
			uri = {endpoint: "#{Constants::ENDPOINT_FILES}", 
					name: "#{path}"}
			header = Constants::HEADER_CONTENT_TYPE_APP_URLENCODED.dup
			unless (startbyte.eql?(0) && bytecount.eql?(0))
				unless bytecount.eql?(0)
					header[:Range] = "bytes=#{startbyte}-#{bytecount}"
				else
					header[:Range] = "bytes=#{startbyte}-"
				end
			end
			# OPTIMISE: rename response to data
			response = request({
					method: 'GET', 
					uri: uri,
					header: header
			})
			unless block.nil?
				block.call(response)	
			else return response
			end
		end

		# List single version
		# @param path [String] file path
		# @param version [Fixnum] desired version of the file referenced by path
		# @return hashes containing metatdata passed version of file
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def list_single_file_version(path, version)
			raise InvalidArgumentError, "Invalid argument, must pass valid path" if Utils::is_blank?(path)
			raise InvalidArgumentError, "Invalid argument, must pass valid path" unless version.is_a?(Integer)
			path.insert(0, '/') unless (path[0] == '/')
			
			uri = {
				endpoint: Constants::ENDPOINT_FILES, 
				name: "#{path}/versions/#{version}"
			}
			
			request({
					method: 'GET', 
					uri: uri, 
					header:  Constants::HEADER_CONTENT_TYPE_APP_URLENCODED.dup
			})
		end
	
		# Promote file version
		# @param path [String] file path
		# @param version [Fixnum] version of file specified by path
		# @return hash containing metadata of promoted file
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def promote_file_version(path, version)
			raise InvalidArgumentError, "Invalid argument, must pass valid path" if Utils::is_blank?(path)
			raise InvalidArgumentError, "Invalid argument, must pass valid version" unless version.is_a?(Integer)
			path.insert(0, '/') unless (path[0] == '/')
			
			query = {operation: "#{Constants::QUERY_OPS_PROMOTE}"}

			uri = {
				endpoint: "#{Constants::ENDPOINT_FILES}", 
				name: "#{path}/versions/#{version}"
			}
			
			request({
					method: 'POST', 
					uri: uri, 
					query: query
			})
		end

		# List versions of file
		# @param path [String] file path
		# @option start_version [Fixnum] version number to begin listing file versions, default 0
		# @option stop_version [Fixnum] version number from which to stop listing file versions, default none
		# @option limit [Fixnum] how many versions to list in the result set. It can be negative, default 10
		# @return array of hashes containing metadata for selected versions of a file as recorded in the History
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def list_file_versions(path, start_version: 0, stop_version: -1, limit: 10)
			raise InvalidArgumentError, "Invalid argument, must pass valid path" if Utils::is_blank?(path)
			path.insert(0, '/') unless (path[0] == '/')
			
			uri = {
				endpoint: "#{Constants::ENDPOINT_FILES}", 
				name: "#{path}/versions"
			}
			query = {
				:'start-version' => start_version, :'limit' => limit
			}
			if stop_version > 0
				query[:'stop-version'] = stop_version
			end
			
			request({
					method: 'GET', 
					uri: uri, 
					query: query,
					header: Constants::HEADER_CONTENT_TYPE_APP_URLENCODED.dup
			})
		end
	
		# Create share
		# @param paths [String []] each path in array represents file/folder
		# @return hash representing metadata of share
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def create_share(paths)
			raise InvalidArgumentError, "Invalid argument, must pass valid list of paths" if Utils::is_blank?(paths)
		
			body = Array(paths).map{|path|
				path.insert(0, '/') unless (path[0] == '/')
				"path=#{Utils::urlencode(path)}"}.join("&")
			
			uri = {
				endpoint: "#{Constants::ENDPOINT_SHARES}"
			}
			
			request({
					method: 'POST', 
					uri: uri, 
					body: body
			})
		end

		# Delete share
		# @param share_key [String] id of the share to be deleted
		# @return hash with success string
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def delete_share(share_key)
			raise InvalidArgumentError, "Invalid argument, must pass valid share key" if Utils::is_blank?(share_key)

			uri = {
				endpoint: "#{Constants::ENDPOINT_SHARES}",
				name: "#{share_key}/"
			}
				
			request({
					method: 'DELETE', 
					uri: uri,
					header:  Constants::HEADER_CONTENT_TYPE_APP_URLENCODED.dup
			})
		end
	
		# List a share	
		# @param path [String]  id of the share to list
		# @return array of hashes containing metatdata of each item in share
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def browse_share(share_key, path: "")
			raise InvalidArgumentError, "Invalid argument, must pass valid path" if Utils::is_blank?(share_key)

			uri = {
				endpoint: "#{Constants::ENDPOINT_SHARES}",
			}
			
			unless Utils::is_blank?(path)
				uri[:name] = "#{share_key}/#{path}/meta"
			else uri[:name] = "#{share_key}/meta"
			end
		
			response = request({
					method: 'GET', 
					uri: uri,
					header:  Constants::HEADER_CONTENT_TYPE_APP_URLENCODED.dup
			})
			# TODO: dont fetch just set
			response.fetch(:items)
		end
	
		# List user's shares
		# @return array of hashes containig metatdata of user's shares
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def list_shares

			uri = {
				endpoint: "#{Constants::ENDPOINT_SHARES}",
			}
			
			request({
					method: 'GET', 
					uri: uri,
					header:  Constants::HEADER_CONTENT_TYPE_APP_URLENCODED.dup
			})
		end

		# Add contents of share to user's filesystem
		# @param share_key [String] id of the share
		# @option path [String] path in user's account to receive share at, default is "/" root
		# @option exists ["RENAME"|"FAIL"|"OVERWRITE"]
		# @return array of hashes representing metadata of items in share
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def receive_share(share_key, path: "", exists: 'RENAME')
			raise InvalidArgumentError, "Invalid argument, must pass valid share key" if Utils::is_blank?(share_key)
			exists = Constants::EXISTS[exists.to_sym] or raise InvalidArgumentError, "Invalid value for exists"
			uri = {
				endpoint: "#{Constants::ENDPOINT_SHARES}",
				name: "#{share_key}/"
			}
			
			form = {exists: exists}
			unless Utils::is_blank?(path)
				path.insert(0, '/') unless (path[0] == '/')
				form[:path] = "#{path}"
			end

			request({
					method: 'POST', 
					uri: uri,
					body: form
			})
		end
			
		# Unlock share
		# @param share_key [String] id of the share
		# @param password [String] password of share
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def unlock_share(share_key, password)
			raise InvalidArgumentError, "Invalid argument, must pass valid path" if Utils::is_blank?(share_key)
			raise InvalidArgumentError, "Invalid argument, must pass valid path" if Utils::is_blank?(password)

			uri = {
				endpoint: "#{Constants::ENDPOINT_SHARES}",
				name: "#{share_key}/unlock"
			}
			
			form = {password: "#{password}"}
			
			request({
					method: 'POST', 
					uri: uri,
					body: form
			})
		end
		
		# Alter share info
		# 	Changes, adds, or removes the share’s password or updates the name
		# @param share_key [String]`id of the share whose attributes are to be changed
		# @option current_password [String] current password of the share
		# @option password [String] new password of share
		# @option name [String] new name of share
		# @return hash containing metadata of share
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		def alter_share_info(share_key, current_password: "", password: "", name: "")
			raise InvalidArgumentError, "Invalid argument, must pass valid path" if Utils::is_blank?(share_key)
			uri = {
				endpoint: "#{Constants::ENDPOINT_SHARES}",
				name: "#{share_key}/info"
			}

			form = {}
			unless Utils::is_blank?(current_password)
					form[:current_password] = "#{current_password}"
			end
			unless Utils::is_blank?(password)
					form[:password] = "#{password}"
			end
			unless Utils::is_blank?(name)
					form[:name] = "#{name}"
			end

			request({
					method: 'POST', 
					uri: uri,
					body: form
			})
		end

		# List history
		# 	list file, folders, share actions history
		# @option start [Fixnum] version number to start listing historical actions from, default -10. It can be negative in order to get most recent actions.
		# @option stop [Fixnum] version number to stop listing historical actions from (non-inclusive)
		# @return array of hashes containing history items
		# @raise Bitcasa::Client:Error
		def list_history(start: -10, stop: 0)

			uri = {
				endpoint: "#{Constants::ENDPOINT_HISTORY}"
			}

			query = {start: start}
			unless stop.eql?(0)
					query[:stop] = stop
			end
			
			request({
					method: 'GET', 
					uri: uri,
					query: query,
					header:  Constants::HEADER_CONTENT_TYPE_APP_URLENCODED.dup
			})
		end

		# Browse trash
		# @option path [String] path to location in user's trash, defaults to root of trash
		# @return array of hashes containing trash items
		# @raise Bitcasa::Client::Error
		def browse_trash(path: "")
			uri = {
				endpoint: "#{Constants::ENDPOINT_TRASH}"
			}
			
			unless Utils::is_blank?(path)
				uri[:name] = "#{path}"
			end
			
			response = request({
					method: 'GET', 
					uri: uri,
					header:  Constants::HEADER_CONTENT_TYPE_APP_URLENCODED.dup
			})
			response.fetch(:items)
		end

		# Delete trash item
		# @option path [String] path to location in user's trash, default all trash items are deleted
		# @return hash containing success: true
		# @raise Bitcasa::Client::Error
		def delete_trash_item(path: "")
			uri = {
				endpoint: "#{Constants::ENDPOINT_TRASH}"
			}
			unless Utils::is_blank?(path)
				uri[:name] = "#{path}"
			end

			request({
					method: 'DELETE', 
					uri: uri,
					header:  Constants::HEADER_CONTENT_TYPE_APP_URLENCODED.dup
			})
		end

		# Recover trash item
		# @param path [String] path to location in user's trash
		# @option restore ["FAIL"|"RESCUE"|"RECREATE"] action to take if the recovery operation encounters issues
		# @option destination [String] rescue or recreate(default root) path depending on restore option
		# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError
		# REVIEW: logic for rescue and recreate
		def recover_trash_item(path, restore: 'FAIL', destination: nil)
			raise InvalidArgumentError, "Invalid argument, must pass valid path" if Utils::is_blank?(path)
			restore = Constants::RESTORE[restore.to_sym] or raise InvalidArgumentError, "Invalid value for restore"
			
			uri = {
				endpoint: "#{Constants::ENDPOINT_TRASH}",
				name: "#{path}"
			}
			
			form = {:'restore' => "#{restore}"}
			if restore.eql?(Constants::RESTORE[:RESCUE])
				unless Utils::is_blank?(destination)
					destination.insert(0, '/') unless (destination[0] == '/')
					form[:'rescue-path'] = "#{destination}"
				end
			elsif restore.eql?(Constants::RESTORE[:RECREATE])
					unless Utils::is_blank?(destination)
					destination.insert(0, '/') unless (destination[0] == '/')
					form[:'recreate-path'] = "#{destination}"
					end
			end
				
			request({
					method: 'POST', 
					uri: uri,
					body: form
			})
		end

	# Request private common method
	# @option method ["POST"|"GET"|"DELETE"]  default "POST"
	# @option uri [Hash] containing endpoint and name that is endpoint suffix
	# @option header [Hash] containing key:value pairs for request header
	# @option query [Hash] containing key:value pairs of query
	# @option body [Hash] containing key:value pairs for post forms or [String] to upload as post data
	# @return hash or data
	# @raise Bitcasa::Client::Error, Bitcasa::Client::InvalidArgumentError	
	# OPTIMIZE: body should be hash only for uploading sting add Sting:string, add more options to post body like file stream, stringio etc.
	# OPTIMIZE: instead of acceping param hash, accept keyword arguments i.e. request method: "POST", uri: {}, header: {}, query: {}, body: {}, &block
	def request(params, &block)
			default_headers = {
				"#{Constants::HEADER_AUTHORIZATION}"=> "Bearer #{@access_token}"
			}
			
			default_uri = {
				host: "#{@host}", 
				endpoint: "", 
				name: ""
			}
			# TODO:	no need to merge if request arguments are keywords representing items in default hash
			req_params = {
				method: 'POST',
				uri: {},
				header: {},
				query: {}, 
				body: {}
			}.merge(params)
			
			req_params[:uri] = default_uri.merge(req_params[:uri])
			unless req_params[:uri][:endpoint].eql?("#{Constants::ENDPOINT_OAUTH}")
					if Utils::is_blank?(@access_token)
						raise SessionNotLinked, "access token is not set, please authenticate"
					end
			end

			req_params[:header] = default_headers.merge(req_params[:header])

			uri = default_uri.merge(req_params[:uri])
			req_params[:uri] = create_url(uri)
		
			if req_params[:body].is_a?(Hash) && req_params[:body].key?(:filepath)
				filepath = req_params[:body].delete(:filepath)
				if req_params[:body].key?(:name)
					file = BCFile.open(filepath)
					file.name = req_params[:body][:name];
				else
			 		file = ::File.open(filepath)
				end
				req_params[:body][:file] = file
			end
			resp = @http_connection.request(req_params, &block)
			create_response(resp)
			rescue Client::Error, StandardError => error
					Client::raise_error(error)
			ensure
		 		unless file.nil?	
					file.close()
				end
		end
		
		def create_url(uri)
			"#{uri[:host]}#{uri[:endpoint]}#{uri[:name]}"
		end
		
		def create_response(response)
			unless response[:content_type].include?("application/json")
				return response.fetch(:content)
			end
			
			resp = Utils::json_to_hash(response.fetch(:content))
			if resp.key?(:result)
				return resp.fetch(:result)
			else return resp; 
			end
		end

		def add_root_to_path(path)
			if Utils.is_blank?(path)
					path = '/'
			elsif !(path[0] == '/')
				path.insert(0, '/')
			end
			path
		end

		private :create_response, :create_url, :request, :move, :copy, :get_meta, :alter_meta, :delete, :add_root_to_path, :request	
	end
end
