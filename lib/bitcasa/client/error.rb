require_relative 'utils'

module Bitcasa
	class Client
		# Defines exceptional behavior.
		# All exceptions raised by Bitcasa SDK can be caught by 
		#		rescue Bitcasa::Client::Errors::Error
		module Errors
		
			# Maps exception classes to error codes returned by Bitcasa CloudFS Service
			BITCASA_ERRORS = {
				9999	=>	'GeneralPanicError',
				9000	=>	'APIError',
				9006	=>	'APICallLimitReached',

				# FileSystem errors
				8001	=>	'InvalidVersion',
				8002	=>	'VersionMismatchIgnored',
				8004	=>	'OrigionalPathNoLongerExists',

				# Shares errors
				6001	=>	'SharePathRequired',
				6002	=>	'SharePathDoesNotExist',
				6003	=>	'WouldExceedQuota',
				6004	=>	'ShareDoesNotExist',

				# Folder errors
				2002	=>	'FolderDoesNotExist',
				2003	=>	'FolderNotFound',
				2004	=>	'UploadToReadOnlyDestinationFailed',
				2005	=>	'MoveToReadOnlyDestinationFailed',
				2006	=>	'CopyToReadOnlyDestinationFailed',
				2007	=>	'RenameOnReadOnlyLocationFailed',
				2008	=>	'DeleteOnReadOnlyLocationFailed',
				2009	=>	'CreateFolderOnReadOnlyLocationFailed',
				2010	=>	'FailedToReadFilesystem',
				2011	=>	'FailedToReadFilesystem',
				2012	=>	'FailedToReadFilesystem',
				2013	=>	'FailedToReadFilesystem',
				2014	=>	'NameConflictCreatingFolder',
				2015	=>	'NameConflictOnUpload',
				2016	=>	'NameConflictOnRename',
				2017	=>	'NameConflictOnMove',
				2018	=>	'NameConflictOnCopy',
				2019	=>	'FailedToSaveChanges',
				2020	=>	'FailedToSaveChanges',
				2021	=>	'FailedToSaveChanges',
				2022	=>	'FailedToBroadcastUpdate',
				2023	=>	'FailedToBroadcastUpdate',
				2024	=>	'FailedToSaveChanges',
				2025	=>	'FailedToSaveChanges',
				2026	=>	'CannotDeleteTheInfiniteDrive',
				2028	=>	'MissingToParameter"',
				2033	=>	'ExistsParameterInvalid',
				2034	=>	'MissingPathParameter',
				2036	=>	'SpecifiedLocationIsReadOnly',
				2037	=>	'SpecifiedSourceIsReadOnly',
				2038	=>	'SpecifiedDestinationIsReadOnly',
				2039	=>	'FolderPathDoesNotExist',
				2040	=>	'PermissionDenied',
				2041	=>	'RenamePermissionDenied',
				2042	=>	'NameConflictInOperation',
				2043	=>	'InvalidOperation',
				2044	=>	'VersionMissingOrIncorrect',
				2045	=>	'InvalidDepth',
				2046	=>	'VersionDoesNotExist',
				2047	=>	'FolderNameRequired',
				2048	=>	'InvalidName',
				2049	=>	'TreeRequired',
				2050	=>	'InvalidVerbose',
				2052	=>	'DirectoryNotEmpty',

				# File errors
				3001	=>	'NotFound',
				3007	=>	'InvalidOperation',
				3008	=>	'InvalidName',
				3009	=>	'InvalidExists',
				3010	=>	'ExtensionTooLong',
				3011	=>	'InvalidDateCreated',
				3012	=>	'InvalidDateMetaLastModified',
				3013	=>	'InvalidDateContentLastModified',
				3014	=>	'MIMETooLong',
				3015	=>	'SizeMustBePositive',
				3018	=>	'NameRequired',
				3019	=>	'SizeRequired',
				3020	=>	'ToPathRequired',
				3021	=>	'VersionMissingOrIncorrect'
			}
	
			# All errors can be rescue by Errors::Error
			#	Top most error class, all bitcasa exceptions can be rescued by this class
			class Error < StandardError; end

			class UnExpectedResponse < Error; end
			class InvalidItemError < Error; end	
			class InvalidShareError < Error; end	
			class OperationNotAllowedError < Error; end	
			class ArgumentError < Error; end
			class SessionNotLinked < Error; end
			
			# All HTTP errors can be rescued by Errors::HttpError
			class HttpError < Error; end

			# All HttpClient errors can be rescued by Errors::ClientError
			#	@!attribute [r] original
			#		@return [Exception] instance
			class ClientError < HttpError
				attr_reader :original
				# @param error [Exception, String] original error
				def initialize(error)
					if error.respond_to?(:backtrace)
						super(error.message)
						@original = error
					else 
						super(error.to_s)
					end
				end

				# @return [String] backtrace of original exception
				def backtrace
						@original.backtrace if original && original.respond_to?(:backtrace)
				end
			end
		
			class ConnectionFailed < ClientError; end
			class TimeoutError < ClientError; end

			# ServerError
			#	@!attribute [r] code
			#		@return [String] http code
			#	@!attribute [r] response
			#		@return [Hash] 
			#			{ :content => String, :content_type => String, :code => String }
			#	@!attribute [r] request
			#		@return [Hash] 
			#			{ :uri => String, :method => String, :param => String }
			class ServerError < HttpError
				attr_reader :code, :response, :request
				# @param message [String] error message
				# @param status [String] error code
				# @param response [Hash] service response body
				# @param request [Hash] service request body
				def initialize(message, status, response={}, request={})
					super(message)
					@code = status
					@response = response
					@request = request
				end
			end
	
			# All bitcasa service errors can be rescued Errors::ServiceError	
			#	@!attribute [r] original
			#		@return [Exception] instance
			class ServiceError < Error
				attr_reader :original
				# @param message [String] error message
				# @param original [Exception] original exception
				def initialize(message, original=nil)
					super(message)
					@original = original
				end

				# @return [String] backtrace of original exception
				def backtrace
						@original.backtrace if original && original.respond_to?(:backtrace)
				end
			end

			class InvalidRequest <  ServiceError; end

			class GeneralPanicError <  ServiceError; end
			class APIError <  ServiceError; end
			class APICallLimitReached < ServiceError; end

			# All filesytem errors can be rescued by Errors::FileSystemError
			class FileSystemError < ServiceError; end
			# All share errors can be rescued by Errors::ShareError
			class ShareError < ServiceError; end
			# All folder errors can be rescued by Errors::FolderError
			class FolderError < ServiceError; end
			# All file errors can be rescued by Errors::FileError
			class FileError < ServiceError; end
			# All endpoint errors can be rescued by Errors::EndpointError
			class EndpointError < ServiceError; end
	
			# FileSystem Errors	

			class InvalidVersion < FileSystemError; end
			class VersionMismatchIgnored < FileSystemError; end
			class OrigionalPathNoLongerExists < FileSystemError; end

			# Share Errors

			class SharePathRequired < ShareError; end
			class SharePathDoesNotExist < ShareError; end
			class WouldExceedQuota < ShareError; end
			class ShareDoesNotExist < ShareError; end

			# Folder Errors

			class FolderDoesNotExist < FolderError; end
			class FolderNotFound < FolderError; end
			class UploadToReadOnlyDestinationFailed < FolderError; end
			class MoveToReadOnlyDestinationFailed < FolderError; end
			class CopyToReadOnlyDestinationFailed < FolderError; end
			class RenameOnReadOnlyLocationFailed < FolderError; end
			class DeleteOnReadOnlyLocationFailed < FolderError; end
			class CreateFolderOnReadOnlyLocationFailed < FolderError; end
			class FailedToReadFilesystem < FolderError; end
			class NameConflictCreatingFolder < FolderError; end
			class NameConflictOnUpload < FolderError; end
			class NameConflictOnRename < FolderError; end
			class NameConflictOnMove < FolderError; end
			class NameConflictOnCopy < FolderError; end
			class FailedToSaveChanges < FolderError; end
			class FailedToBroadcastUpdate < FolderError; end
			class CannotDeleteTheInfiniteDrive < FolderError; end
			class FolderMissingToParameter < FolderError; end
			class ExistsParameterInvalid < FolderError; end
			class MissingPathParameter < FolderError; end
			class SpecifiedLocationIsReadOnly < FolderError; end
			class SpecifiedSourceIsReadOnly < FolderError; end
			class SpecifiedDestinationIsReadOnly < FolderError; end
			class FolderPathDoesNotExist < FolderError; end
			class PermissionDenied < FolderError; end
			class RenamePermissionDenied < FolderError; end
			class NameConflictInOperation < FolderError; end
			class InvalidOperation < FolderError; end
			class VersionMissingOrIncorrect < FolderError; end
			class InvalidDepth < FolderError; end
			class VersionMissingOrIncorrect < FolderError; end
			class VersionDoesNotExist < FolderError; end
			class FolderNameRequired < FolderError; end
			class InvalidName < FolderError; end
			class TreeRequired < FolderError; end
			class InvalidVerbose < FolderError; end
			class DirectoryNotEmpty < FolderError; end

			# FileErrors

			class SizeRequired < FileError; end
			class NotFound < FileError; end 
			class FileInvalidOperation < FileError; end
			class FileInvalidName < FileError; end
			class InvalidExists < FileError; end
			class ExtensionTooLong < FileError; end
			class InvalidDateCreated < FileError; end
			class InvalidDateMetaLastModified < FileError; end
			class InvalidDateContentLastModified < FileError; end
			class MIMETooLong < FileError; end
			class SizeMustBePositive < FileError; end
			class NameRequired < FileError; end
			class SizeRequired < FileError; end
			class ToPathRequired < FileError; end
			class FileVersionMissingOrIncorrect < FileError; end
			class InvalidPath < EndpointError; end
			class AlreadyExists < EndpointError; end
			class NotAllowed < EndpointError; end

			# Raise service error
			# 		raises specific exception mapped by Bitcasa error code in json message
			# @param error [ServerError] contains message and http code of ServerError
			#
			# @raise ServiceError mapped by code in message parameter in ServerError
			def self.raise_service_error(error)
				begin
					hash = Utils.json_to_hash(error.message)
				rescue StandardError
					raise ServiceError.new(error.message, error)
				end
				raise ServiceError.new(error.message, error) unless hash.key?(:error)

				if hash[:error].is_a?(Hash)
					code, message = Utils.hash_to_arguments(hash[:error], 
						:code, :message)
				else
					message = hash.fetch(:message) { hash[:error] }	
					code = hash.fetch(:error_code, nil)
				end

				raise ServiceError.new(message, error) unless code && BITCASA_ERRORS.key?(code)
				raise const_get(BITCASA_ERRORS[code]).new(message, error)
			end	
		end	
	end
end
