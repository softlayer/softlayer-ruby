module SoftLayer
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
  class Client
    attr_reader :username, :api_key, :endpoint_url;

    def initialize(options = {})
      @services = { }

      # pick up the username from the options, the global, or assume no username
      @username = options[:username] || $SL_API_USERNAME || ""

      # do a similar thing for the api key
      @api_key = options[:api_key] || $SL_API_KEY || ""

      # and the endpoint url
      @endpoint_url = options[:endpoint_url] || $SL_API_BASE_URL || API_PUBLIC_ENDPOINT || ""

      raise "A SoftLayer Client requires a username" if !@username || @username.empty?
      raise "A SoftLayer Client requires an api_key" if !@api_key || @api_key.empty?
      raise "A SoftLayer Clietn requires an enpoint URL" if !@endpoint_url || @endpoint_url.empty?
    end

    # Returns a service with the given name.
    #
    # If a service has already been created by this client that same service
    # will be returned each time it is called for by name. Otherwise the system 
    # will try to construct a new service object and return that.
    #
    #
    # If the service has to be created then the service_options will be passed
    # along to the creative function.  However, when returning a previously created
    # Service, the service_options will be ignored.
    #
    # If the service_name provided does not start with 'SoftLayer__' that prefix
    # will be added 
    # en
    def service_named(service_name, service_options = {})
      # strip whitespace from service_name and 
      # ensure that it start with "SoftLayer_".
      # 
      # if it does not, then add it
      service_name.strip!
      if service_name && !service_name.empty?
        if not service_name =~ /\ASoftLayer_/
          service_name = "SoftLayer_#{service_name}"
        end
      end

      # if we've already created this service, just return it
      # otherwise create a new service
      if !@services[service_name]
        full_options = {:client => self}

        # override my default options with the ones passed in
        full_options.merge! service_options

        @services[service_name] = SoftLayer::Service.new(service_name, full_options)      
      end

      @services[service_name]
    end

    def [](service_name)
      service_named(service_name)
    end
  end
end

