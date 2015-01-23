require "cgi"
require 'base64'
require 'openssl'
require 'multi_json'
require 'ostruct'

module Bitcasa

	# Utility functions module, used to handle common tasks
	module Utils
		extend self
		# :TODO 
		def self.urlencode(value)
			CGI.escape("#{value}")
		end
	
		#does not handle nested hash
		def self.hash_to_urlencoded_str(hash = {}, delim, join_with)
			hash.map{|k,v| 
				"#{urlencode(k)}#{delim}#{urlencode(v)}"}.join("#{join_with}")
		end
		# :TODO 
		def self.generate_auth_signature(endpoint, params, headers, secret)

			params_encoded = hash_to_urlencoded_str(params, "=", "&")
			headers_encoded = hash_to_urlencoded_str(headers, ":", "&")
			string_to_sign = "POST&#{endpoint}&#{params_encoded}&#{headers_encoded}" 	
			hmac_str = OpenSSL::HMAC.digest('sha1', secret, string_to_sign)
			Base64.strict_encode64("#{hmac_str}")
		end
		# :TODO 
		def self.json_to_hash(json_str)
#	OpenStruct.new(MultiJson.load(hash))	
			MultiJson.load(json_str, :symbolize_keys=>true)
		end
		# :TODO 
		def self.hash_to_json(hash={})
#	OpenStruct.new(MultiJson.load(hash))	
			MultiJson.dump(hash)
		end
		# :TODO 
		def self.hash_to_arguments(hash, *field)
			if field.any? {|f| hash.key?(f)}
				return hash.values_at(*field)
			end
		end	
		# :TODO 
		def self.is_blank?(var)
				var.respond_to?(:empty?) ? var.empty? : !var
		end
	end
end
