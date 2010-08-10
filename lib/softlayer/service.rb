# Copyright (c) 2010, SoftLayer Technologies, Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#  * Neither SoftLayer Technologies, Inc. nor the names of its contributors may
#    be used to endorse or promote products derived from this software without
#    specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'rubygems'
require 'net/https'
require 'json/add/core'

module SoftLayer
  # A subclass of Exception with nothing new provided.  This simply provides
  # a unique type for exceptions from the SoftLayer API
  class SoftLayerAPIException < RuntimeError
  end

  # An APIParameterFilter is an intermediary object that understands how
  # to accept the other API parameter filters and carry their values to
  # method_missing in Service. Instances of this class are created
  # internally by the Service in it's handling of a method call and you
  # should not have to create instances of this class directly.
  #
  # Instead, to use an API filter, you add a filter method to the call
  # chain when you call a method through a SoftLayer::Service
  #
  # For example, given a SoftLayer::Service instance called "account_service"
  # you could take advantage of the API filter that identifies a particular
  # object known to that service using the 'object_with_id" method :
  #
  #     account_service.object_with_id(91234).getSomeAttribute
  #
  # The invocation of object_with_id will cause an instance of this
  # class to be instantiated with the service as its target.
  #
  class APIParameterFilter
    attr_accessor :target
    attr_accessor :parameters

    def initialize
      @parameters = {}
    end

    def server_object_id
      self.parameters[:server_object_id]
    end

    def server_object_mask
      self.parameters[:object_mask]
    end

    def object_with_id(value)
      merged_object = APIParameterFilter.new;
      merged_object.target = self.target
      merged_object.parameters = @parameters.merge({ :server_object_id => value })
      merged_object
    end

    def object_mask(*args)
      merged_object = APIParameterFilter.new;
      merged_object.target = self.target
      merged_object.parameters = @parameters.merge({ :object_mask => args }) if args && !args.empty?
      merged_object
    end

    def method_missing(method_name, *args, &block)
      return @target.call_softlayer_api_with_params(method_name, self, args, &block)
    end
  end

  # = SoftLayer API Service
  #
  # Instances of this class represent services in the SoftLayer API.
  #
  # You create a service with the name of one of the SoftLayer services
  # (documented on the http://sldn.softlayer.com web site).  Once created
  # you can use the service to make method calls to the SoftLayer API.
  #
  # A typical use might look something like
  #
  #   account_service = SoftLayer::Service("SoftLayer_Account", :username=>"<your user name here>" :api_key=>"<your api key here>")
  #
  # then to invoke a method simply call the service:
  #
  #   account_service.getOpenTickets
  #   => {... lots of information here representing the list of open tickets ...}
  #
  class Service
    # The name of the service that this object calls. Cannot be emtpy or nil.
    attr_accessor :service_name

    # A username passed as authentication for each request. Cannot be emtpy or nil.
    attr_accessor :username

    # An API key passed as part of the authentication of each request. Cannot be emtpy or nil.
    attr_accessor :api_key

    # The base URL for requests that are passed to the server. Cannot be emtpy or nil.
    attr_accessor :endpoint_url

    # Initialize an instance of the Client class. You pass in the service name
    # and optionally hash arguments specifying how the client should access the
    # SoftLayer API.
    #
    # The following symbols can be used as hash arguments to pass options to the constructor:
    # - <tt>:username</tt> - a non-empty string providing the username to use for requests to the service
    # - <tt>:api_key</tt> - a non-empty string providing the api key to use for requests to the service
    # - <tt>:endpoint_url</tt> - a non-empty string providing the endpoint URL to use for requests to the service
    #
    # If any of the options above are missing then the constructor will try to use the corresponding
    # global variable declared in the SoftLayer Module:
    # - <tt>$SL_API_USERNAME</tt>
    # - <tt>$SL_API_KEY</tt>
    # - <tt>$SL_API_BASE_URL</tt>
    #
    def initialize(service_name, options = {})
      raise SoftLayerAPIException.new("Please provide a service name") if service_name.nil? || service_name.empty?
      self.service_name = service_name;

      # pick up the username provided in options or the default one from the *globals*
      self.username = options[:username] || $SL_API_USERNAME || ""

      # pick up the api_key provided in options or the default one from the globals
      self.api_key = options[:api_key] || $SL_API_KEY || ""

      # pick up the url endpoint from options or the default one in the globals OR the
      # public endpoint
      self.endpoint_url = options[:endpoint_url] || $SL_API_BASE_URL || API_PUBLIC_ENDPOINT

      if($DEBUG)
        @method_missing_call_depth = 0
      end
    end #initalize


    # Use this as part of a method call chain to identify a particular
    # object as the target of the request. The parameter is the SoftLayer
    # object identifier you are interested in. For example, this call
    # would return the ticket whose ID is 35212
    #
    #   ticket_service.object_with_id(35212).getObject
    #
    def object_with_id(object_of_interest)
      proxy = APIParameterFilter.new
      proxy.target = self

      return proxy.object_with_id(object_of_interest)
    end

    # Use this as part of a method call chain to add an object mask to
    # the request.The arguments to object mask should be the strings
    # that are the keys of the mask:
    #
    #   ticket_service.object_mask("createDate", "modifyDate").getObject
    #
    # Before being used, the string passed will be url-encoded by this
    # routine. (i.e. there is no need to url-encode the strings beforehand)
    #
    # As an implementation detail, the object_mask becomes part of the
    # query on the url sent to the API server
    #
    def object_mask(*args)
      proxy = APIParameterFilter.new
      proxy.target = self

      return proxy.object_mask(*args)
    end

    # This is the primary mechanism by which requests are made. If you call
    # the service with a method it doesn't understand, it will send a call to
    # the endpoint for a method of the same name.
    #
    def method_missing(method_name, *args, &block)
      # During development, if you end up with a stray name in some
      # code, you can end up in an infinite recursive loop as method_missing
      # tries to resolve that name (believe me... it happens).
      # This mechanism looks for what it considers to be an unreasonable call
      # depth and kills the loop quickly.
      if($DEBUG)
        @method_missing_call_depth += 1
        if @method_missing_call_depth > 3 # 3 is somewhat arbitrary... really the call depth should only ever be 1
          @method_missing_call_depth = 0
          raise "stop infinite recursion #{method_name}, #{args.inspect}"
        end
      end

      # if we're in debug mode, we put out a little helpful information
      puts "SoftLayer::Service#method_missing called #{method_name}, #{args.inspect}" if $DEBUG

      result = call_softlayer_api_with_params(method_name, nil, args, &block);

      if($DEBUG)
        @method_missing_call_depth -= 1
      end

      return result
    end

    # Issue an HTTP request to call the given method from the SoftLayer API with
    # the parameters and arguments given.
    #
    # Parameters are information _about_ the call, the object mask or the
    # particular object in the SoftLayer API you are calling.
    #
    # Arguments are the arguments to the SoftLayer method that you wish to
    # invoke.
    #
    # This is intended to be used in the internal
    # processing of method_missing and need not be called directly.
    def call_softlayer_api_with_params(method_name, parameters, args, &block)
      # find out what URL will invoke the method (with the given parameters)
      request_url = url_to_call_method(method_name, parameters)

      # marshall the arguments into the http_request
      request_body = marshall_arguments_for_call(args)

      # construct an HTTP request for that method with the given URL
      http_request = http_request_for_method(method_name, request_url, request_body);
      http_request.basic_auth(self.username, self.api_key)

      # Send the url request and recover the results.  Parse the response (if any)
      # as JSON
      json_results = issue_http_request(request_url, http_request, &block)
      if json_results
        # The JSON parser for Ruby parses JSON "Text" according to RFC 4627, but
        # not JSON values.  As a result, 'JSON.parse("true")' yields a parsing
        # exception. To work around this, we force the result JSON text by
        # including it in Array markers, then take the first element of the
        # resulting array as the result of the parsing. This should allow values 
        # like true, false, null, and numbers to parse the same way they would in
        # a browser.
        parsed_json = JSON.parse("[ #{json_results} ]")[0]

        # if the results indicate an error, convert it into an exception
        if parsed_json.kind_of?(Hash) && parsed_json['error']
          raise SoftLayerAPIException.new(parsed_json['error'])
        end
      else
        parsed_json = nil
      end

      # return the results, if any
      return parsed_json
    end

    # Marshall the arguments into a JSON string suitable for the body of
    # an HTTP message. This is intended to be used in the internal
    # processing of method_missing and need not be called directly.
    def marshall_arguments_for_call(args)
      request_body = nil;

      if(args && !args.empty?)
        request_body = {"parameters" => args}.to_json
      end

      return request_body
    end

    # Given a method name, determine the appropriate HTTP mechanism
    # for sending a request to execute that method to the server.
    # and create a Net::HTTP request of that type. This is intended
    # to be used in the internal processing of method_missing and
    # need not be called directly.
    def http_request_for_method(method_name, method_url, request_body)
      content_type_header = {"Content-Type" => "application/json"}

      case method_name.to_s
      when /^get/
		# if the user has provided some arguments to the call, we 
		# use a POST instead of a GET in spite of the method name.
		if request_body && !request_body.empty?
	        url_request = Net::HTTP::Post.new(method_url.request_uri(), content_type_header)
		else 
        	url_request = Net::HTTP::Get.new(method_url.request_uri())
		end
      when /^edit/
        url_request = Net::HTTP::Put.new(method_url.request_uri(), content_type_header)
      when /^delete/
        url_request = Net::HTTP::Delete.new(method_url.request_uri())
      when /^create/, /^add/, /^remove/, /^findBy/
        url_request = Net::HTTP::Post.new(method_url.request_uri(), content_type_header)
      else
		# The name doesn't match one of our expected patterns... Use GET if 
		# there are no parameters, and POST if the user has given parameters.
		if request_body && !request_body.empty?
	        url_request = Net::HTTP::Post.new(method_url.request_uri(), content_type_header)
		else 
        	url_request = Net::HTTP::Get.new(method_url.request_uri())
		end
      end

      # This warning should be obsolete as we should be using POST if the user
 	  # has provided parameters. I'm going to leave it in, however, on the off
	  # chance that it catches a case we aren't expecting.
      if request_body && !url_request.request_body_permitted?
        $stderr.puts("Warning - The HTTP request for #{method_name} does not allow arguments to be passed to the server")
      else
        # Otherwise, add the arguments as the body of the request
        url_request.body = request_body
      end

	  url_request
    end

    # Connect to the network and request the content of the resource
    # specified. This is used to do the actual work of connecting
    # to the SoftLayer servers and exchange data. This is intended
    # to be used in the internal processing of method_missing and
    # need not be called directly.
    def issue_http_request(request_url, http_request, &block)
      # create and run an SSL request
      https = Net::HTTP.new(request_url.host, request_url.port)
      https.use_ssl = (request_url.scheme == "https")

      # This line silences an annoying warning message if you're in debug mode
      https.verify_mode = OpenSSL::SSL::VERIFY_NONE if $DEBUG

      https.start do |http|

        puts "SoftLayer API issuing an HTTP request for #{request_url}" if $DEBUG

        response = https.request(http_request)

        case response
        when Net::HTTPSuccess
          return response.body
        else
          # We have an error. It might have a meaningful error message
          # from the server. Check to see if there is a body and whether
          # or not that body parses as JSON.  If it does, then we return
          # that as a result (assuming it's an error)
          json_parses = false
          body = response.body

          begin
            if body
              JSON.parse(body)
              json_parses = true
            end
          rescue => json_parse_exception
            json_parses = false;
          end

          # Let the HTTP library generate and raise an exception if
          # the body was empty or could not be parsed as JSON
          response.value() if !json_parses

          return body
        end
      end
    end

    # Construct a URL for calling the given method on this endpoint and
    # expecting a JSON response. This is intended to be used in the internal
    # processing of method_missing and need not be called directly.
    def url_to_call_method(method_name, parameters)
      method_path = method_name.to_s

      # if there's an object ID on the parameters, add that to the URL
      if(parameters && parameters.server_object_id)
        method_path = parameters.server_object_id.to_s + "/" + method_path
      end

      # tag ".json" onto the method path (if it's not already there)
      method_path.sub!(%r|(\.json){0,1}$|, ".json")

      # put the whole thing together into a URL
      # (reusing a variation on the clever regular expression above. This one appends a "slash"
      # to the service name if theres not already one there otherwise. Without it URI.join
      # doesn't do the right thing)
      uri = URI.join(self.endpoint_url, self.service_name.sub(%r{/*$},"/"), method_path)

      query_string = nil

      if(parameters && parameters.server_object_mask)
        mask_value = parameters.server_object_mask.to_sl_object_mask.map { |mask_key| URI.encode(mask_key.to_s.strip) }.join(";")
        query_string = "objectMask=#{mask_value}"
      end

      uri.query = query_string

      return uri
    end

    # Change the username. The username cannot be nil or the empty string.
    def username= (name)
      raise SoftLayerAPIException.new("Please provide a username") if name.nil? || name.empty?
      @username = name.strip
    end

    # Change the api_key. It cannot be nil or the empty string.
    def api_key= (new_key)
      raise SoftLayerAPIException.new("Please provide an api_key") if new_key.nil? || new_key.empty?
      @api_key = new_key.strip
    end

    # Change the endpoint_url. It cannot be nil or the empty string.
    def endpoint_url= (new_url)
      raise SoftLayerAPIException.new("The endpoint url cannot be nil or empty") if new_url.nil? || new_url.empty?
      @endpoint_url = new_url.strip
    end
  end # class Service
end # module SoftLayer