#
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

require 'rubygems'
require 'savon'

class String
  # This code was taken from ActiveSupport in Rails and modified just a bit to remove
  # parts that would handle non-english text.  The odd name is there specifically to
  # prevent collisions with other methods
  def sl_camelcase_to_underscore
    word = self.dup
    word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
    word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
    word.tr!("-", "_")
    word.downcase!
    word
  end
end

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

    def result_limit(offset, limit)
      merged_object = APIParameterFilter.new;
      merged_object.target = self.target
      merged_object.parameters = @parameters.merge({ :result_offset => offset, :result_limit => limit })
      merged_object
    end

    def server_result_limit
      self.parameters[:result_limit]
    end

    def server_result_offset
      self.parameters[:result_offset]
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

    # A username passed as authentication for each request. Cannot be emtpy or nil.
    attr_accessor :username

    # An API key passed as part of the authentication of each request. Cannot be emtpy or nil.
    attr_accessor :api_key
    
    # The name of the service that this object calls. Cannot be emtpy or nil.
    attr_accessor :service_name

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
    # - <tt>:savon_client_options</tt> - A hash of options that are passed to the savon SOAP client created for the service
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

      # pick up the username from the options, the global, or assume no username
      self.username = options[:username] || $SL_API_USERNAME || ""
      
      # do a similar thing for the api key
      self.api_key = options[:api_key] || $SL_API_KEY || ""
  
      # and the endpoint url
      self.endpoint_url = options[:endpoint_url] || $SL_API_BASE_URL || API_PUBLIC_ENDPOINT
      
      # Create the SOAP client object that will be used for calls to this service
      savon_options = {
				:wsdl => (@endpoint_url + @service_name + '?wsdl'),
        :convert_request_keys_to => :none,
        :convert_response_tags_to => :none,
        :log => $DEBUG || false,
				:soap_header => {'tns:authenticate' => { 'username' => @username, "apiKey" => @api_key } }
      }

      # if the caller provided any savon options, put them into the client options hash
      if(options[:savon_client_options]) then
        savon_options = savon_options.merge(options[:savon_client_options])
      end

      @_soap_service = Savon.client(savon_options);

      # this has proven to be very helpful during debugging.  It helps prevent infinite recursion
      # when you don't get a method call just right
      @method_missing_call_depth = 0 if $DEBUG
    end
  
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

    def result_limit(offset, limit)
      proxy = APIParameterFilter.new
      proxy.target = self
      return proxy.result_limit(offset, limit)
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
      
      additional_headers = {};

      if(parameters && parameters.server_object_id)        
        additional_headers = {"tns:#{@service_name}InitParameters" => { "id" => parameters.server_object_id}}
      end

      if(parameters && parameters.server_object_mask)
        object_mask = SoftLayer::ObjectMask.new()
        object_mask.subproperties = parameters.server_object_mask

        additional_headers = additional_headers.merge({ "tns:SoftLayer_ObjectMask" => { "mask" => object_mask.to_sl_object_mask } })
      end

      if (parameters && parameters.server_result_limit)
        additional_headers = additional_headers.merge("tns:resultLimit" => { "offset" => (parameters.server_result_offset || 0), "limit" => parameters.server_result_limit })
      end

      soap_symbol = method_name.to_s.sl_camelcase_to_underscore.to_sym

      if(additional_headers && !additional_headers.empty?)
        soap_result = @_soap_service.call(soap_symbol, *args, :soap_header => additional_headers)
      else
        soap_result = @_soap_service.call(soap_symbol, *args)
      end
      
      soap_return_value = soap_result.body["#{method_name}Response"]["#{method_name}Return"]
      
      if soap_return_value.has_key? "@SOAP_ENC:arrayType" then
        soap_return_value = soap_return_value["item"]
      end

      return soap_return_value
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
  end # Service class
end # module SoftLayer