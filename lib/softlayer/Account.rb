module SoftLayer
  class Account
    attr_reader :account_id

    # Retrieve the default account object from the given service.
    # This should be a SoftLayer::Service with the service id of 
    # SoftLayer_Account.
    #
    # account_service = SoftLayer::Service.new("SoftLayer_Account")
    # account = SoftLayer::Account.default_account(account_service)
    #
    def self.default_account(account_service)
      network_hash = account_service.getObject()
      new(network_hash)
    end
    
    # Initializes an Account from the given hash. Presumably this
    # hash was returned by a network service.
    #
    # The has is expected to include an object ID in a key that has
    # either the string "id" or the symbol :id. If the hash does
    # not include that key, then an ArgumentError exception is thrown.
    #
    # In typical usage, you should not have to create instances of
    # this class directly... instead you should use the class method
    # default_account to obtain an account object from the SoftLayer_Account
    # service.
    #
    def initialize(network_hash)
      raise ArgumentError, "Accounts must be created with a network hash" if network_hash.nil?

      # convert all the keys in the incomming hash to symbols but keep their values
      @sl_hash = network_hash.inject({}) { |new_value, pair| new_value[pair[0].to_sym] = pair[1]; new_value }
      
      raise ArgumentError, "Network hash must include an :id" if !@sl_hash.has_key?(:id)
    end
    
    # the account_id field comes from the hash
    def account_id
      value = @sl_hash[:id]
    end
    
    # When calling "puts" with an object that defines method_missing, the
    # system will try to coerce the object to an array.  We override to_ary
    # to indicate that that coersion is not meaninful.
    def to_ary
      nil
    end

    # We define respond_to? as a companion to our method_missing and the fact
    # that we look like we create accessors for all the items in the hash
    def respond_to?(method_symbol)
      return (@sl_hash && @sl_hash.has_key?(method_symbol)) || super
    end
    
    # We redefine method_missing to make our object respond to
    # requests for values that are "hidden" in the SoftLayer data
    # fields hash (@sl_hash).  For example, if the hash contains the 
    # field "firstName", then you should be able to call
    # "myObject.firstName" and get back that value from the hash.
    def method_missing(method_symbol, *args, &block)
      # Only consider method calls with no arguments and no blocks
      if(@sl_hash && args.empty? && !block)        
        # if the method's name can be found in our sl_hash return the value from there
        if @sl_hash.has_key? method_symbol
          return @sl_hash[method_symbol]
        else
          super
        end
      else
        super
      end
    end
  end
end