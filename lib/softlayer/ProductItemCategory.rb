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
  # This struct represents a configuration option that can be included in
  # a product order.  Strictly speaking the only information required for
  # the product order is the price_id, the rest of the information is provided
  # to make the object friendly to humans who may be searching for the
  # meaning of a given price_id.
  ProductConfigurationOption = Struct.new(:price_id, :description, :capacity, :units, :setupFee, :laborFee, :oneTimeFee, :recurringFee, :hourlyRecurringFee) do

    # Is it evil, or just incongruous to give methods to a struct?

    # returns true if the configurtion option has no fees associated with it.
    def free?
      self.setupFee == 0 && self.laborFee == 0 && self.oneTimeFee == 0 && self.recurringFee == 0 && self.hourlyRecurringFee == 0
    end
  end

  # The goal of this class is to make it easy for scripts (and scripters) to
  # discover what product configuration options exist that can be added to a
  # product order.
  #
  # Instances of this class are created by and discovered in the context
  # of a ProductPackage object. There should not be a need to create instances
  # of this class directly.
  #
  # This class rougly represents entities in the +SoftLayer_Product_Item_Category+
  # service.
  class ProductItemCategory < ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader:
    # The categoryCode is a primary identifier for a particular
    # category.  It is a string like 'os' or 'ram'
    sl_attr :categoryCode

    ##
    # :attr_reader:
    # The name of a category is a friendly, readable string
    sl_attr :name

    sl_dynamic_attr :configuration_options do |config_opts|
      config_opts.should_update? do
        # only retrieved once per instance
        @configuration_options == nil
      end

      config_opts.to_update do
        # This method assumes that the group and price item data was sent in
        # as part of the +network_hash+ used to initialize this object (as is done)
        # by the ProductPackage class. That class, in turn, gets its information
        # from SoftLayer_Product_Package::getCategories which does some complex
        # work on the back end to ensure the prices returned are correct.
        #
        # If this object was created in any other way, the configuration
        # options might be incorrect. So Caveat Emptor.
        #
        # Options are divided into groups (for convenience in the
        # web UI), but this code collapses the groups.
        self['groups'].collect do |group|
          group['prices'].sort{|lhs,rhs| lhs['sort'] <=> rhs['sort']}.collect do |price_item|
            ProductConfigurationOption.new(
              price_item['id'],
              price_item['item']['description'],
              price_item['item']['capacity'],
              price_item['item']['units'],
              price_item['setupFee'] ? price_item['setupFee'].to_f : 0.0,
              price_item['laborFee'] ? price_item['laborFee'].to_f : 0.0,
              price_item['oneTimeFee'] ? price_item['oneTimeFee'].to_f : 0.0,
              price_item['recurringFee'] ? price_item['recurringFee'].to_f : 0.0,
              price_item['hourlyRecurringFee'] ? price_item['hourlyRecurringFee'].to_f : 0.0
              )
          end
        end.flatten # flatten out the individual group arrays.
      end
    end

    def service
      softlayer_client["SoftLayer_Product_Item_Category"].object_with_id(self.id)
    end

    ##
    # If the category has a single option (regardless of fees) this method will return
    # that option.  If the category has more than one option, this method will
    # return the first that it finds with no fees associated with it.
    #
    # If there are multiple options with no fees, it simply returns the first it finds
    #
    # Note that the option found may NOT be the same default option that is given
    # in the web-based ordering system.
    #
    # If there are multiple options, and all of them have associated fees, then this method
    # **will** return nil.
    #
    def default_option
      if configuration_options.count == 1
        configuration_options.first
      else
        configuration_options.find { |option| option.free? }
      end
    end

    # The ProductItemCategory class augments the base initialization by accepting
    # a boolean variable, +is_required+, which (when true) indicates that this category
    # is required for orders against the package that created it.
    def initialize(softlayer_client, network_hash, is_required)
      super(softlayer_client, network_hash)
      @is_required = is_required
    end

    # Returns true if this category is required in its package
    def required?()
      return @is_required
    end
  end
end