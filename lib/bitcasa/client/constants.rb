module Bitcasa
	class Client
		# Declares bitcasa constants
		module Constants
			REQUEST_KEY_METHOD = "method"
			REQUEST_KEY_URI = "uri"
			HTTP_METHOD_KEY = "method"
			HTTP_METHOD_POST = "POST"
			HTTP_METHOD_GET = "GET"

			URI_PREFIX_HTTPS = "https://"
			#  DATE_FORMAT define date format
			DATE_FORMAT = "%a, %e %b %Y %H:%M:%S %Z"   
			# HEADER_DATE constant string                                     
			HEADER_DATE = "Date"	
			# HEADER_CONTENT_TYP content-type string						
			HEADER_CONTENT_TYPE = "Content-Type"
			# HEADER_AUTHORIZATION authorization 
			HEADER_AUTH_PREFIX_BCS = "BCS"
			# HEADER_AUTHORIZATION authorization 
			HEADER_AUTHORIZATION = "Authorization"
			# CONTENT_TYPE_APP_URLENCODED url for application
			CONTENT_TYPE_APP_URLENCODED = "application/x-www-form-urlencoded;charset=utf-8"
			# CONTENT_TYPE_MULTI content type for multipart
			CONTENT_TYPE_MULTI = "multipart/form-data"
			# HEADER_CONTENT_TYPE_APP_URLENCODED 
			HEADER_CONTENT_TYPE_APP_URLENCODED = {"#{HEADER_CONTENT_TYPE}" => 
				"#{CONTENT_TYPE_APP_URLENCODED}" }

			PARAM_EMAIL = "email"
			PARAM_FIRST_NAME = "first_name"
			PARAM_LAST_NAME = "last_name"	
			# PARAM_GRANT_TYPE grant_type
			PARAM_GRANT_TYPE = "grant_type"
			# PARAM_USER for username
			PARAM_USER = "username"
			# PARAM_PASSWORD for password
			PARAM_PASSWORD = "password";
			KEY_ENDPOINT = "endpoint"
			# ENDPOINT_OAUTH for oauth2 token
			ENDPOINT_OAUTH = "/v2/oauth2/token"
			# ENDPOINT_PING for ping
			ENDPOINT_PING = "/v2/ping"
			# ENDPOINT_CUSTOMERS defines admin cloudfs customers
			ENDPOINT_CUSTOMERS = "/v2/admin/cloudfs/customers/"
			# ENDPOINT_USER_PROFILE for user profile
			ENDPOINT_USER_PROFILE = "/v2/user/profile/"
			# ENDPOINT_FOLDERS for folders
			ENDPOINT_FOLDERS = "/v2/folders/"
			# ENDPOINT_FILES for files
			ENDPOINT_FILES = "/v2/files"
			# ENDPOINT_SHARES for share forlder
			ENDPOINT_SHARES = "/v2/shares/"
			# ENDPOINT_HISTORY for history
			ENDPOINT_HISTORY = "/v2/history"
			# ENDPOINT_TRASH for trash
			ENDPOINT_TRASH = "/v2/trash/"
			# QUERY_OPS_CREATE creates query ops
			QUERY_OPS_CREATE = "create"
			# QUERY_OPS_COPY for copying query ops
			QUERY_OPS_COPY = "copy"
			# QUERY_OPS_MOVE for move 
			QUERY_OPS_MOVE = "move"
			# QUERY_OPS_PROMOTE for promote
			QUERY_OPS_PROMOTE = "promote"
			# EXISTS for fail, overwrite, rename & reuse actions
			EXISTS = {FAIL: "fail", OVERWRITE: "overwrite", RENAME: "rename", REUSE: "reuse"}
			# VERSION_CONFLICT for fail or ignore.
			VERSION_CONFLICT = {FAIL: "fail", IGNORE: "ignore"}
			# RESTORE fail, rescue & recreate action
			RESTORE = {FAIL: "fail", RESCUE: "rescue", RECREATE: "recreate"}
		end
	end
end
