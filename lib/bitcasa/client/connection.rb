require 'httpclient'
require_relative 'utils'
require_relative 'error'

module Bitcasa
	class Client
		# Provides restful interface
		#	
		# @author Mrinal Dhillon
		# Maintains a persistent instance of class HTTPClient, 
		#		since HTTPClient instance is MT-safe and can be called from 
		#		several threads without synchronization after setting up an instance, 
		#		same behaviour is expected from Connection class.	
		#	
		# @see http://www.rubydoc.info/gems/httpclient
		#		
		# @example
		#		conn = Connection.new
		# 	response = conn.request('GET', "https://www.example.com")
		class Connection

      # Creates Connection instance
			#
			# @option params [Fixnum] :connect_timeout (60) for handshake, 
			#			defualts to 60 as per httpclient documentation
			# @option params [Fixnum] :send_timeout (120) for send request, 
			#			defaults to 120 sec as httpclient documentation, set 0 is for no timeout
			# @option params [Fixnum] :recive_timeout (60) for receiving response, 
			#			defaults to 60 sec as httpclient documentation, set 0 is for no timeout
			def initialize(**params)
				@persistent_conn = HTTPClient.new
				@persistent_conn.cookie_manager = nil
				connect_timeout, send_timeout, receive_timeout = 
						params.values_at(:connect_timeout, :send_timeout, :receive_timeout)
				@persistent_conn.connect_timeout = connect_timeout if connect_timeout
				@persistent_conn.send_timeout = send_timeout if send_timeout
				@persistent_conn.receive_timeout = receive_timeout if receive_timeout
			end
		
			# Disconnects all keep alive connections and intenal sessions
			def unlink
				@persistent_conn.reset_all
			end

			# Sends request to specified url
			#		Calls HTTPClient#request
			#
			# @param method [Symbol] (:get, :put, :post, :delete) http verb
			# @param uri [String, URI] represents complete url to web resource
			#
			# @option params [Hash] :headers http request headers
			# @option params [Hash] :query part of url 	
			#				ie. https://hosts/path?key=value&key1=value1
			# @option params [Hash, String] :body to post key:value forms, string
			#			mutipart upload a file by sending File instance
			#			body: { :file => File :name => String }
			# @return [Hash] response hash containing content, conten_type and http code
			#			{ :content => String, :content_type => String, :code => String }
			# @raise [Errors::ClientError, Errors::ServerError]
			# 		ClientError wraps httpclient exceptions 
			#				i.e. timeout, connection failed etc.
			#			ServerError contains error message and code from server
			# @optimize add request, response context to exceptions, async request support
			#
			# @review Behaviour in case of error with follow_redirect set to true 
			#		and callback block for get, observed is that if server return 
			#		message as response body in case of error, message is discarded 
			#		and unable to fetch it. Opened issue#234 on nahi/httpclient github
			def request(method, uri, **params, &block)
				method = method.to_s.downcase.to_sym
				req_params = params.reject { |_,v| Utils.is_blank?(v) }
				req_params = req_params.merge({ follow_redirect: true }) if method == :get
				resp = @persistent_conn.request(method, uri, req_params, &block)

				status = resp.status.to_i
				response = {code: resp.code}
				response[:content] = resp.content 
				response[:content_type] = resp.header['Content-Type'].first
				status = resp.status.to_i
				if status < 200 || status >=400 || resp.redirect?
					message = Utils.is_blank?(resp.content) ? resp.reason : resp.content
					
					request = {}
					request[:uri] = uri.to_s
					request[:method] = method.to_s
					# @optimize copying params as string makes exception only informative, 
					#		should instead return deep copy of request params so that 
					#		applications can evaluate error.
					request[:params] = req_params.to_s
					fail Errors::ServerError.new(message, status, response, request)
				end
				response
	
				rescue HTTPClient::TimeoutError
					raise Errors::TimeoutError.new($!)
				rescue HTTPClient::BadResponseError
					raise Errors::ClientError.new($!)
				rescue Errno::ECONNREFUSED, EOFError, SocketError
					raise Errors::ConnectionFailed.new($!)
			end
		end
	end
end
