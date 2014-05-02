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

    ##
    # Asks a model object to reload itself from the SoftLayer API.
    #
    # This is only implemented in subclasses.
    #
    def refresh_details(object_mask = nil)
      network_hash = self.softlayer_properties(object_mask)
      @sl_hash = network_hash.inject({}) { | new_hash, pair | new_hash[pair[0].to_sym] = pair[1]; new_hash }
    end

    ##
    # Subclasses implement this method.  The implementation should
    # make a request to the SoftLayer API and retrieve an up-to-date
    # representation of this object expressed as a property hash.
    def softlayer_properties(object_mask = nil)
      raise RuntimeError.new("Abstract method softlayer_properties in ModelBase was called")
    end

    # This is defined for the benefit of Ruby 1.8.7 where "#id" used to
    # return the same thing as object_id
    def id
      if @sl_hash.has_key? :id
        @sl_hash[:id]
      else
        super
      end
    end

    def respond_to?(method_symbol)
      if @sl_hash
        if @sl_hash.has_key? method_symbol
          true
        else
          super
        end
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