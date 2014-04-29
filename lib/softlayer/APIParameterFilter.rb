
module SoftLayer
# An <tt>APIParameterFilter</tt> is an intermediary object that understands how
# to accept the other API parameter filters and carry their values to
# <tt>method_missing</tt> in <tt>Service</tt>. Instances of this class are created
# internally by the <tt>Service</tt> in its handling of a method call and you
# should not have to create instances of this class directly.
#
# Instead, to use an API filter, you add a filter method to the call
# chain when you call a method through a <tt>SoftLayer::Service</tt>
#
# For example, given a <tt>SoftLayer::Service</tt> instance called <tt>account_service</tt>
# you could take advantage of the API filter that identifies a particular
# object known to that service using the <tt>object_with_id</tt> method :
#
#     account_service.object_with_id(91234).getSomeAttribute
#
# The invocation of <tt>object_with_id</tt> will cause an instance of this
# class to be created with the service as its target.
#
class APIParameterFilter
  attr_reader :target
  attr_reader :parameters

  def initialize(target, starting_parameters = nil)
    @target = target
    @parameters = starting_parameters || {}
  end

  # Adds an API filter that narrows the scope of a call to an object with
  # a particular ID.  For example, if you want to get the ticket
  # with an ID of 12345 from the ticket service you might use
  #
  # ticket_service.object_with_id(12345).getObject
  def object_with_id(value)
    # we create a new object in case the user wants to store off the
    # filter chain and reuse it later
    APIParameterFilter.new(self.target, @parameters.merge({ :server_object_id => value }))
  end

  # Use this as part of a method call chain to add an object mask to
  # the request. The arguments to object mask should be well formed
  # Extended Object Mask strings:
  #
  #   ticket_service.object_mask(
  #     "mask[createDate, modifyDate]",
  #     "mask(SoftLayer_Some_Type).aProperty").getObject
  #
  # The object_mask becomes part of the request sent to the server
  #
  def object_mask(*args)
    raise ArgumentError, "object_mask expects object mask strings" if args.empty? || (1 == args.count && !args[0])
    raise ArgumentError, "object_mask expects strings" if args.find{ |arg| !arg.kind_of?(String) }

    mask_parser = ObjectMaskParser.new()
    object_masks = args.collect { |mask_string| mask_parser.parse(mask_string)}.flatten
    object_mask = (@parameters[:object_mask] || []) + object_masks

    # we create a new object in case the user wants to store off the
    # filter chain and reuse it later
    APIParameterFilter.new(self.target, @parameters.merge({ :object_mask => object_mask }));
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
    APIParameterFilter.new(self.target, @parameters.merge({ :result_offset => offset, :result_limit => limit }))
  end

  # Adds an object_filter to the result.  An Object Filter allows you
  # to specify criteria which are used to filter the results returned
  # by the server.
  def object_filter(filter)
    raise ArgumentError, "Object mask expects mask properties" if filter.nil?

    # we create a new object in case the user wants to store off the
    # filter chain and reuse it later
    APIParameterFilter.new(self.target, @parameters.merge({:object_filter => filter}));
  end

  # A utility method that returns the server object ID (if any) stored
  # in this parameter set.
  def server_object_id
    self.parameters[:server_object_id]
  end

  # a utility method that returns the object mask (if any) stored
  # in this parameter set.
  def server_object_mask
    if parameters[:object_mask] && !parameters[:object_mask].empty?
      reduced_masks = parameters[:object_mask].inject([]) do |merged_masks, object_mask|
        mergeable_mask = merged_masks.find { |mask| mask.can_merge_with? object_mask }
        if mergeable_mask
          mergeable_mask.merge object_mask
        else
          merged_masks.push object_mask
        end

        merged_masks
      end      
      
      if reduced_masks.count == 1
        reduced_masks[0].to_s
      else
        "[#{reduced_masks.collect{|mask| mask.to_s}.join(',')}]"
      end
    else
      nil
    end
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

    if(!block && method_name.to_s.match(/[[:alnum:]]+/))
      @target.call_softlayer_api_with_params(method_name, self, args)
    else
      super
    end
  end
end

end # module SoftLayer