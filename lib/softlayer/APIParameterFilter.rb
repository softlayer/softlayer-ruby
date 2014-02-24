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
    puts "SoftLayer::APIParameterFilter#method_missing called #{method_name}, #{args.inspect}" if $DEBUG

    return @target.call_softlayer_api_with_params(method_name, self, args, &block)
  end
end

end # module SoftLayer