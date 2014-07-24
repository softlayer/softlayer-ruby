#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  # This class is used to order changes to a virtual server.  Although
  # the class is named "upgrade" this class can also be used for "downgrades"
  # (i.e. changing attributes to a smaller, or slower, value)
  #
  # The class can also be used to discover what upgrades are available
  # for a given virtual server.
  #
  class VirtualServerUpgradeOrder
    # The virtual server that this order is designed to upgrade.
    attr_reader :virtual_server
    
    # The number of cores the server should have after the upgrade.
    # If this is nil, the the number of cores will not change
    attr_accessor :cores
    
    # The amount of RAM (in GB) that the server should have after the upgrade
    # If this is nil, the ram will not change
    attr_accessor :ram
    
    # The port speed (in Mega bits per second) that the server should have
    # after the upgrade.  This is typically a value like 100, or 1000
    # If this is nil, the port speeds will not change
    attr_accessor :max_port_speed
    
    # The date and time when you would like the upgrade to be processed.
    # This should simply be a Time object.  If nil then the upgrade
    # will be performed immediately
    attr_accessor :upgrade_at
    
    ##
    # Create an upgrade order for the virtual server provided.
    #
    def initialize(virtual_server)
      raise "A virtual server must be provided at the time a virtual server order is created" if !virtual_server || !virtual_server.kind_of?(SoftLayer::VirtualServer)
      @virtual_server = virtual_server
    end

    ##
    # Sends the order represented by this object to SoftLayer for validation.
    #
    # If a block is passed to verify, the code will send the order template
    # being constructed to the block before the order is actually sent for
    # validation.
    #
    def verify()
      if has_order_items?
        order_object = self.order_object
        order_object = yield order_object if block_given?

        @virtual_server.softlayer_client["Product_Order"].verifyOrder(order_object)
      end
    end

    ##
    # Places the order represented by this object.  This is likely to 
    # involve a change to the charges on an account.
    #
    # If a block is passed to this routine, the code will send the order template
    # being constructed to that block before the order is sent
    #
    def place_order!()
      if has_order_items?
        order_object = self.order_object
        order_object = yield order_object if block_given?

        @virtual_server.softlayer_client["Product_Order"].placeOrder(order_object)
      end
    end

    ##
    # Return a list of values that are valid for the :cores attribute
    def core_options()
      self._item_prices_in_category("guest_core").map { |item_price| item_price["item"]["capacity"].to_i}.sort.uniq
    end

    ##
    # Return a list of values that are valid for the :memory attribute
    def memory_options()
      self._item_prices_in_category("ram").map { |item_price| item_price["item"]["capacity"].to_i}.sort.uniq
    end

    ##
    # Returns a list of valid values for max_port_speed
    def max_port_speed_options(client = nil)
      self._item_prices_in_category("port_speed").map { |item_price| item_price["item"]["capacity"].to_i}.sort.uniq
    end

    private

    ##
    # Returns true if this order object has any upgrades specified
    #
    def has_order_items?
      @cores != nil || @ram != nil || @max_port_speed != nil
    end

    ##
    # Returns a list of the update item prices, in the given category, for the server
    #
    def _item_prices_in_category(which_category)
      @virtual_server.upgrade_options.select { |item_price| item_price["categories"].find { |category| category["categoryCode"] == which_category } }
    end
    
    ##
    # Searches through the upgrade items pricess known to this server for the one that is in a particular category
    # and whose capacity matches the value given. Returns the item_price or nil
    #
    def _item_price_with_capacity(which_category, capacity)
      self._item_prices_in_category(which_category).find { |item_price| item_price["item"]["capacity"].to_i == capacity}
    end
    
    ## 
    # construct an order object
    #
    def order_object
      prices = []
      
      cores_price_item = @cores ? _item_price_with_capacity("guest_core", @cores) : nil
      ram_price_item = @ram ? _item_price_with_capacity("ram", @ram) : nil
      max_port_speed_price_item = @max_port_speed ? _item_price_with_capacity("port_speed", @max_port_speed) : nil
      
      prices << { "id" => cores_price_item["id"] } if cores_price_item
      prices << { "id" => ram_price_item["id"] } if ram_price_item
      prices << { "id" => max_port_speed_price_item["id"] } if max_port_speed_price_item

      # put together an order
      upgrade_order = {
        'complexType' => 'SoftLayer_Container_Product_Order_Virtual_Guest_Upgrade',
        'virtualGuests' => [{'id' => @virtual_server.id }],
        'properties' => [{'name' => 'MAINTENANCE_WINDOW', 'value' => @upgrade_at ? @upgrade_at.iso8601 : Time.now.iso8601}],
        'prices' => prices
      }
    end
  end # VirtualServerUpgradeOrder
end # SoftLayer Module
