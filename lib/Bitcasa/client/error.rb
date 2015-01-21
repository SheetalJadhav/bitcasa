module Bitcasa
	class Client
			
		# Bitcasa errors map Bitcasa:Client::Error children to errors returned by Bitcasa Server
		# OPTIMIZE: 
		#		Write a general wrapper on these errors so that 
		#				consuming application can do general exception handling for bitcasa sdk
		# 	Add request, response context, backtrace to exceptions

		BITCASA_ERRORS = {
			9999	=>	'GeneralPanicError',
			9000	=>	'APIError',
			9006	=>	'APICallLimitReached',

			8001	=>	'InvalidVersion',
			8002	=>	'VersionMismatchIgnored',
			8004	=>	'OrigionalPathNoLongerExists',
		
			6001	=>	'SharePathRequired',
			6002	=>	'SharePathDoesNotExist',
			6003	=>	'WouldExceedQuota',
			6004	=>	'ShareDoesNotExist',

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
		# Error 
		class Error < StandardError; end
		
		# REVIEW: this is only exception class that does not fall under Bitcasa::Client::Error exception class, forcing appliactions to handle atleast two exceptions i.e. Bitcasa::Client:Error and Bitcasa::Client::InvalidArgumentError
		class InvalidArgumentError < ArgumentError; end
		# ClientError
		class ClientError < Error; end
		# ConnectionFailed
		class ConnectionFailed < ClientError; end
		# TimeoutError
		class TimeoutError < ClientError; end
		# SessionNotLinked 
		class SessionNotLinked < Error; end
		# ServerError
		class ServerError < Error
			attr_reader :code
			# initialize message & sets the status
			# @param message [String] sets a string
			# @param status [String] error, warning or info
			def initialize(message, status)
				super(message)
				@code = status
			end
		end
		# UnExpectedResponse
		class UnExpectedResponse < Error; end
		# InvalidRequest
		class InvalidRequest <  Error; end
		# GeneralPanicError
		class GeneralPanicError <  Error; end
		# APIError
		class APIError <  Error; end
		# APICallLimitReached
		class APICallLimitReached < Error; end
		# FileSystemError
		class FileSystemError < Error; end
		# ShareError
		class ShareError < Error; end
		# FolderError
		class FolderError < Error; end
		# FileError
		class FileError < Error; end
		# EndpointError
		class EndpointError < Error; end
		# InvalidVersion 
		class InvalidVersion < FileSystemError; end
		# VersionMismatchIgnored
		class VersionMismatchIgnored < FileSystemError; end
		# OrigionalPathNoLongerExists
		class OrigionalPathNoLongerExists < FileSystemError; end
		# SharePathRequired
		class SharePathRequired < ShareError; end
		# SharePathDoesNotExist
		class SharePathDoesNotExist < ShareError; end
		# WouldExceedQuota
		class WouldExceedQuota < ShareError; end
		# ShareDoesNotExist
		class ShareDoesNotExist < ShareError; end
		# FolderDoesNotExist
		class FolderDoesNotExist < FolderError; end
		# FolderNotFound
		class FolderNotFound < FolderError; end
		# UploadToReadOnlyDestinationFailed
		class UploadToReadOnlyDestinationFailed < FolderError; end
		# MoveToReadOnlyDestinationFailed
		class MoveToReadOnlyDestinationFailed < FolderError; end
		# CopyToReadOnlyDestinationFailed
		class CopyToReadOnlyDestinationFailed < FolderError; end
		# RenameOnReadOnlyLocationFailed
		class RenameOnReadOnlyLocationFailed < FolderError; end
		# DeleteOnReadOnlyLocationFailed
		class DeleteOnReadOnlyLocationFailed < FolderError; end
		# CreateFolderOnReadOnlyLocationFailed 
		class CreateFolderOnReadOnlyLocationFailed < FolderError; end
		# FailedToReadFilesystem
		class FailedToReadFilesystem < FolderError; end
		# NameConflictCreatingFolder
		class NameConflictCreatingFolder < FolderError; end
		# NameConflictOnUpload
		class NameConflictOnUpload < FolderError; end
		# NameConflictOnRename
		class NameConflictOnRename < FolderError; end
		# NameConflictOnMove 
		class NameConflictOnMove < FolderError; end
		# NameConflictOnCopy
		class NameConflictOnCopy < FolderError; end
		# FailedToSaveChanges
		class FailedToSaveChanges < FolderError; end
		# FailedToBroadcastUpdate 
		class FailedToBroadcastUpdate < FolderError; end
		# CannotDeleteTheInfiniteDrive 
		class CannotDeleteTheInfiniteDrive < FolderError; end
		# FolderMissingToParameter
		class FolderMissingToParameter < FolderError; end
		# ExistsParameterInvalid
		class ExistsParameterInvalid < FolderError; end
		# MissingPathParameter
		class MissingPathParameter < FolderError; end
		# SpecifiedLocationIsReadOnly
		class SpecifiedLocationIsReadOnly < FolderError; end
		# SpecifiedSourceIsReadOnly
		class SpecifiedSourceIsReadOnly < FolderError; end
		# SpecifiedDestinationIsReadOnly
		class SpecifiedDestinationIsReadOnly < FolderError; end
		# FolderPathDoesNotExist
		class FolderPathDoesNotExist < FolderError; end
		# PermissionDenied
		class PermissionDenied < FolderError; end
		# RenamePermissionDenied
		class RenamePermissionDenied < FolderError; end
		# NameConflictInOperation
		class NameConflictInOperation < FolderError; end
		# InvalidOperation
		class InvalidOperation < FolderError; end
		# VersionMissingOrIncorrect
		class VersionMissingOrIncorrect < FolderError; end
		# InvalidDepth
		class InvalidDepth < FolderError; end
		# VersionMissingOrIncorrect
		class VersionMissingOrIncorrect < FolderError; end
		# VersionDoesNotExist
		class VersionDoesNotExist < FolderError; end
		# FolderNameRequired 
		class FolderNameRequired < FolderError; end
		# InvalidName
		class InvalidName < FolderError; end
		# TreeRequired
		class TreeRequired < FolderError; end
		# InvalidVerbose
		class InvalidVerbose < FolderError; end
		# DirectoryNotEmpty
		class DirectoryNotEmpty < FolderError; end
		# SizeRequired
		class SizeRequired < FileError; end
		# NotFound
		class NotFound < FileError; end 
		# FileInvalidOperation
		class FileInvalidOperation < FileError; end
		# FileInvalidName
		class FileInvalidName < FileError; end
		# InvalidExists
		class InvalidExists < FileError; end
		# ExtensionTooLong
		class ExtensionTooLong < FileError; end
		# InvalidDateCreated
		class InvalidDateCreated < FileError; end
		# InvalidDateMetaLastModified
		class InvalidDateMetaLastModified < FileError; end
		# InvalidDateContentLastModified 
		class InvalidDateContentLastModified < FileError; end
		# MIMETooLong
		class MIMETooLong < FileError; end
		# SizeMustBePositive
		class SizeMustBePositive < FileError; end
		# NameRequired
		class NameRequired < FileError; end
		# SizeRequired
		class SizeRequired < FileError; end
		# ToPathRequired
		class ToPathRequired < FileError; end
		# FileVersionMissingOrIncorrect
		class FileVersionMissingOrIncorrect < FileError; end
		# InvalidPath
		class InvalidPath < EndpointError; end
		# AlreadyExists
		class AlreadyExists < EndpointError; end
		# NotAllowed
		class NotAllowed < EndpointError; end

		# Raise server error
		# 		converts Bitcasa::Client::Server exception to bitcasa error specific exception mapped by Bitcasa error code in json message.
		# @param error [Bitcasa::Client::ServerError] contains message and code of ServerError
		# @raise Bitcasa::Client::Error mapped by code in message parameter in ServerError
		def self.raise_server_error(error)
			begin
				hash = Utils::json_to_hash(error.message)
			rescue StandardError
				raise error
			end

			if hash.key?(:error)
				if hash[:error].is_a?(Hash)
					code, message = Utils::hash_to_arguments(hash[:error], :code, :message)
				elsif hash.key?(:message) 
					message = hash[:message]
				else message = hash[:error]; end
			else raise error; end
		
			if (!code.nil?) && (BITCASA_ERRORS.key?(code))
				raise const_get(BITCASA_ERRORS[code]).new(message)
			else raise InvalidRequest.new(message); end
		end	
	 	# raise error 
	 	# @param error[Bitcasa::Client::ServerError] contains message and code of ServerError
		def self.raise_error(error)
			if error.is_a?(ServerError)
				raise_server_error(error)
			else raise error
			end
		end
	end	
end
