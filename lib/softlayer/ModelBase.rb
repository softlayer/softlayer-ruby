module SoftLayer
  class ModelBase
    attr_reader :softlayer_service

    def initialize(softlayer_service, network_hash)
      raise ArgumentError, "A hash is required" if nil == network_hash
      
      @softlayer_service = softlayer_service
      @sl_hash = network_hash.inject({}) { | new_hash, pair | new_hash[pair[0].to_sym] = pair[1]; new_hash }
      
      raise ArgumentError, "The hash must have an id" unless @sl_hash.has_key?(:id)
    end
    
    def to_ary
      return nil
    end
    
    def method_missing(method_symbol, *args, &block)
      if(@sl_hash && 0 == args.length && !block)
        if @sl_hash.has_key? method_symbol
          @sl_hash[method_symbol]
        else
          super
        end
      else
        super
      end
    end
  end
end