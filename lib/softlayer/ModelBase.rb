module SoftLayer
  class ModelBase
    attr_reader :softlayer_client

    def initialize(softlayer_client, network_hash)
      raise ArgumentError, "A hash is required" if nil == network_hash

      @softlayer_client = softlayer_client
      @sl_hash = network_hash.inject({}) { | new_hash, pair | new_hash[pair[0].to_sym] = pair[1]; new_hash }

      raise ArgumentError, "The hash must have an id" unless @sl_hash.has_key?(:id)
      raise ArgumentError, "id must be non-nil and non-empty" unless @sl_hash[:id] && !@sl_hash.to_s.empty?
    end

    def to_ary
      return nil
    end

    # This is defined for the benefit of 1.8.7 where "#id" used to
    # return the same thing as object_id
    def id
      if @sl_hash.has_key? :id
        @sl_hash[:id]
      else
        super
      end
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