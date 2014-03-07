
module SoftLayer
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

  # Adds an API filter that narrows the scope of a call to an object with
  # a particular ID.  For example, if you want to get the ticket
  # with an ID of 12345 from the ticket service you might use
  #
  # ticket_service.object_with_id(12345).getObject
  def object_with_id(value)
    # we create a new object in case the user wants to store off the
    # filter chain and reuse it later
    merged_object = APIParameterFilter.new;
    merged_object.target = self.target
    merged_object.parameters = @parameters.merge({ :server_object_id => value })
    merged_object
  end

  # Adds an objectMask to a call so that the amount of information returned will be
  # limited.  For example, if you wanted to get the ids of all the open tickets
  # for an accoun you might use:
  #
  # account_service.object_mask(id).getOpenTickets
  def object_mask(*args)
    raise ArgumentError, "Object mask expects mask properties" if args.empty? || (1 == args.count && !args[0])

    # we create a new object in case the user wants to store off the
    # filter chain and reuse it later
    merged_object = APIParameterFilter.new;
    merged_object.target = self.target
    merged_object.parameters = @parameters.merge({ :object_mask => args })
    merged_object
  end

  # Adds a result limit which helps you page through a long list of entities
  #
  # The offset is the index of the first item you wish to have returned
  # The limit describes how many items you wish the call to return.
  #
  # For example, if you wanted to get five open tickets from the account
  # starting with the tenth item in the open tickets list you might call
  #
  # account_service.result_limit(10, 5).getOpenTickets
  def result_limit(offset, limit)
    # we create a new object in case the user wants to store off the
    # filter chain and reuse it later
    merged_object = APIParameterFilter.new;
    merged_object.target = self.target
    merged_object.parameters = @parameters.merge({ :result_offset => offset, :result_limit => limit })
    merged_object
  end

  # Adds an object_filter to the result.  An Object Filter allows you
  # to specify criteria which are used to filter the results returned
  # by the server.
  def object_filter(filter)
    raise ArgumentError, "Object mask expects mask properties" if filter.nil?

    # we create a new object in case the user wants to store off the
    # filter chain and reuse it later
    merged_object = APIParameterFilter.new;
    merged_object.target = self.target
    merged_object.parameters = @parameters.merge({:object_filter => filter})
    merged_object
  end

  # A utility method that returns the server object ID (if any) stored 
  # in this parameter set.
  def server_object_id
    self.parameters[:server_object_id]
  end

  # a utility method that returns the object mask (if any) stored
  # in this parameter set.
  def server_object_mask
    self.parameters[:object_mask]
  end

  # a utility method that returns the starting index of the result limit (if any) stored
  # in this parameter set.
  def server_result_limit
    self.parameters[:result_limit]
  end

  # a utility method that returns the starting index of the result limit offset (if any) stored
  # in this parameter set.
  def server_result_offset
    self.parameters[:result_offset]
  end

  def server_object_filter
    self.parameters[:object_filter]
  end

  # This allows the filters to be used at the end of a long chain of calls that ends
  # at a service.
  def method_missing(method_name, *args, &block)
    puts "SoftLayer::APIParameterFilter#method_missing called #{method_name}, #{args.inspect}" if $DEBUG

    return @target.call_softlayer_api_with_params(method_name, self, args, &block)
  end
end

end # module SoftLayer