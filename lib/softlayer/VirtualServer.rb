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

require 'time'

module SoftLayer
  ##
  # Instance of this class represent servers that are virtual machines in the
  # SoftLayer environment.
  #
  # This class roughly corresponds to the entity SoftLayer_Virtual_Guest in the
  # API.
  #
  class VirtualServer < Server
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader:
    # A count of the nubmer of virtual processing cores allocated
    # to the server.
    sl_attr :cores, 'maxCpu'

    ##
    # :attr_reader:
    # The date the Virtual Server was provisioned.  This attribute can be
    # nil if the SoftLayer system has not yet finished provisioning the
    # server (consequently this attribute is used by the #wait_until_ready
    # method to determine when a server has been provisioned)
    sl_attr :provisionDate

    ##
    # :attr_reader:
    # The active transaction (if any) for this virtual server. Transactions
    # are used to make configuration changes to the server and only one
    # transaction can be active at a time.
    sl_attr :activeTransaction

    ##
    # :attr_reader:
    # Storage devices attached to the server. Storage may be local
    # to the host running the Virtual Server, or it may be located
    # on the SAN
    sl_attr :blockDevices

    ##
    # :attr_reader:
    # The last operating system reload transaction that was
    # run for this server. #wait_until_ready compares the
    # ID of this transaction to the ID of the active transaction
    # to determine if an OS reload is in progress.
    sl_attr :lastOperatingSystemReload

    ##
    # A virtual server can find out about items that are
    # available for upgrades.
    #
    sl_dynamic_attr :upgrade_options do |resource|
      resource.should_update? do
        @upgrade_items == nil
      end

      resource.to_update do
        service.object_with_id(self.id).object_mask("mask[id,categories.categoryCode,item[id,capacity,units,attributes,prices]]").getUpgradeItemPrices(true)
      end
    end

    ##
    # IMMEDIATELY cancel this virtual server
    #
    def cancel!
      self.service.object_with_id(self.id).deleteObject()
    end

    ##
    # This routine submits an order to upgrade the cpu count of the virtual server.
    # The order may result in additional charges being applied to SoftLayer account
    #
    # This routine can also "downgrade" servers (set their cpu count lower)
    #
    # The routine returns true if the order is placed and false if it is not
    #
    def upgrade_cores!(num_cores)
      upgrade_item_price = _item_price_in_category("guest_core", num_cores)
      _order_upgrade_item!(upgrade_item_price) if upgrade_item_price
      nil != upgrade_item_price
    end

    ##
    # This routine submits an order to change the RAM available to the virtual server.
    # Pass in the desired amount of RAM for the server in Gigabytes
    #
    # The order may result in additional charges being applied to SoftLayer account
    #
    # The routine returns true if the order is placed and false if it is not
    #
    def upgrade_RAM!(ram_in_GB)
      upgrade_item_price = _item_price_in_category("ram", ram_in_GB)
      _order_upgrade_item!(upgrade_item_price) if upgrade_item_price
      nil != upgrade_item_price
    end

    ##
    # This routine submits an order to change the maximum nic speed of the server
    # Pass in the desired speed in Megabits per second (typically 10, 100, or 1000)
    # (since you may choose a slower speed this routine can also be used for "downgrades")
    #
    # The order may result in additional charges being applied to SoftLayer account
    #
    # The routine returns true if the order is placed and false if it is not
    #
    def upgrade_max_port_speed!(network_speed_in_Mbps)
      upgrade_item_price = _item_price_in_category("port_speed", network_speed_in_Mbps)
      _order_upgrade_item!(upgrade_item_price) if upgrade_item_price
      nil != upgrade_item_price
    end

    ##
    # Capture a disk image of this virtual server for use with other servers.
    #
    # image_name will become the name of the image in the portal.
    #
    # If include_attached_storage is true, the images of attached storage will be
    # included as well.
    #
    # The image_notes should be a string and will be added to the image as notes.
    #
    def capture_image(image_name, include_attached_storage = false, image_notes = nil)
      disk_filter = lambda { |disk| disk['device'] == '0' }
      disk_filter = lambda { |disk| disk['device'] == '1' } if include_attached_storage

      disks = self.blockDevices.select(&disk_filter)

      service.object_with_id(id).createArchiveTransaction(image_name, disks, notes) if disks && !disks.empty?
    end

    ##
    # Repeatedly polls the API to find out if this server is 'ready'.
    #
    # The server is ready when it is provisioned and any operating system reloads have completed.
    #
    # If wait_for_transactions is true, then the routine will poll until all transactions
    # (not just an OS Reload) have completed on the server.
    #
    # max_trials is the maximum number of times the routine will poll the API
    # seconds_between_tries is the polling interval (in seconds)
    #
    # The routine returns true if the server was found to be ready. If max_trials
    # is exceeded and the server is still not ready, the routine returns false
    #
    # If a block is passed to this routine it will be called on each trial with
    # a boolean argument representing whether or not the server is ready
    #
    # Calling this routine will (in essence) block the thread on which the request is made.
    #
    def wait_until_ready(max_trials, wait_for_transactions = false, seconds_between_tries = 2)
      # pessimistically assume the server is not ready
      num_trials = 0
      begin
        self.refresh_details()

        has_os_reload = has_sl_property? :lastOperatingSystemReload
        has_active_transaction = has_sl_property? :activeTransaction

        reloading_os = has_active_transaction && has_os_reload && (self.lastOperatingSystemReload['id'] == self.activeTransaction['id'])
        provisioned = has_sl_property? :provisionDate

        # a server is ready when it is provisioned, not reloading the OS
        # (and if wait_for_transactions is true, when there are no active transactions).
        ready = provisioned && !reloading_os && (!wait_for_transactions || !has_active_transaction)

        num_trials = num_trials + 1

        yield ready if block_given?

        sleep(seconds_between_tries) if !ready && (num_trials <= max_trials)
      end until ready || (num_trials >= max_trials)

      ready
    end

    ##
    # Retrive the virtual server with the given server ID from the API
    #
    # The options may include the following keys
    # * <b>+:object_mask+</b> (string) - A object mask of properties, in addition to the default properties, that you wish to retrieve for the server
    #
    def self.server_with_id(softlayer_client, server_id, options = {})
      service = softlayer_client["Virtual_Guest"]
      service = service.object_mask(default_object_mask.to_sl_object_mask)

      if options.has_key?(:object_mask)
        service = service.object_mask(options[:object_mask])
      end

      server_data = service.object_with_id(server_id).getObject()

      return VirtualServer.new(softlayer_client, server_data)
    end

    ##
    # Retrieve a list of virtual servers from the account.
    #
    # You may filter the list returned by adding options:
    # * <b>+:hourly+</b> (boolean) - Include servers billed hourly in the list
    # * <b>+:monthly+</b> (boolean) - Include servers billed monthly in the list
    # * <b>+:tags+</b> (array) - an array of strings representing tags to search for on the instances
    # * <b>+:cpus+</b> (int) - return virtual servers with the given number of (virtual) CPUs
    # * <b>+:memory+</b> (int) - return servers with at least the given amount of memory (in MB. e.g. 4096 = 4GB)
    # * <b>+:hostname+</b> (string) - return servers whose hostnames match the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:domain+</b> (string) - filter servers to those whose domain matches the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:local_disk+</b> (boolean) - include servers that do, or do not, have local disk storage
    # * <b>+:datacenter+</b> (string) - find servers whose short data center name (e.g. dal05, sjc01) matches the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:nic_speed+</b> (int) - include servers with the given nic speed (in Mbps, usually 10, 100, or 1000)
    # * <b>+:public_ip+</b> (string) - return servers whose public IP address matches the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:private_ip+</b> (string) - same as :public_ip, but for private IP addresses
    #
    # Additionally you may provide options related to the request itself:
    # * <b>+:object_mask+</b> (string) - A object mask of properties, in addition to the default properties, that you wish to retrieve for the servers
    # * <b>+:result_limit+</b> (hash with :limit, and :offset keys) - Limit the scope of results returned.
    #
    def self.find_servers(softlayer_client, options_hash = {})
      object_filter = {}

      option_to_filter_path = {
        :cpus => "virtualGuests.maxCpu",
        :memory => "virtualGuests.maxMemory",
        :hostname => "virtualGuests.hostname",
        :domain => "virtualGuests.domain",
        :local_disk => "virtualGuests.localDiskFlag",
        :datacenter => "virtualGuests.datacenter.name",
        :nic_speed => "virtualGuests.networkComponents.maxSpeed",
        :public_ip => "virtualGuests.primaryIpAddress",
        :private_ip => "virtualGuests.primaryBackendIpAddress"
      }

      if options_hash.has_key?(:local_disk) then
        options_hash[:local_disk] = options_hash[:local_disk] ? 1 : 0
      end

      # For each of the options in the option_to_filter_path map, if the options hash includes
      # that particular option, add a clause to the object filter that filters for the matching
      # value
      option_to_filter_path.each do |option, filter_path|
        object_filter.merge!(SoftLayer::ObjectFilter.build(filter_path, options_hash[option])) if options_hash.has_key?(option)
      end

      # Tags get a much more complex object filter operation so we handle them separately
      if options_hash.has_key?(:tags)
        object_filter.merge!(SoftLayer::ObjectFilter.build("virtualGuests.tagReferences.tag.name", {
          'operation' => 'in',
          'options' => [{
            'name' => 'data',
            'value' => options_hash[:tags]
            }]
          } ));
      end

      required_properties_mask = 'mask.id'

      service = softlayer_client['Account']
      service = service.object_filter(object_filter) unless object_filter.empty?
      service = service.object_mask(default_object_mask.to_sl_object_mask)

      if options_hash.has_key? :object_mask
        service = service.object_mask(options_hash[:object_mask])
      end

      if options_hash.has_key?(:result_limit)
        offset = options[:result_limit][:offset]
        limit = options[:result_limit][:limit]

        service = service.result_limit(offset, limit)
      end

      case
      when options_hash[:hourly] && options_hash[:monthly]
        virtual_server_data = service.getVirtualGuests()
      when options_hash[:hourly]
        virtual_server_data = service.getHourlyVirtualGuests()
      when options_hash[:monthly]
        virtual_server_data = service.getMonthlyVirtualGuests()
      else
        virtual_server_data = service.getVirtualGuests()
      end

      virtual_server_data.collect { |server_data| VirtualServer.new(softlayer_client, server_data) }
    end

    ##
    # Returns the default object mask used when fetching servers from the API
    def self.default_object_mask
      sub_mask = {
        "mask(SoftLayer_Virtual_Guest)" => [
          'createDate',
          'modifyDate',
          'provisionDate',
          'dedicatedAccountHostOnlyFlag',
          'lastKnownPowerState.name',
          'powerState',
          'status',
          'maxCpu',
          'maxMemory',
          'activeTransaction[id, transactionStatus[friendlyName,name]]',
          'networkComponents[id, status, speed, maxSpeed, name, macAddress, primaryIpAddress, port, primarySubnet]',
          'lastOperatingSystemReload.id',
          'blockDevices',
          'blockDeviceTemplateGroup[id, name, globalIdentifier]'
        ]
      }

      super.merge(sub_mask)
    end #default_object_mask

    ##
    # Returns the SoftLayer Service used to work with instances of this class. For Virtual Servers that is +SoftLayer_Virtual_Guest+
    # This routine is largely an implementation detail of this object framework
    def service
      return softlayer_client["Virtual_Guest"]
    end

    private

    ##
    # Searches through the upgrade items pricess known to this server for the one that is in a particular category
    # and whose capacity matches the value given. Returns the item_price or nil
    #
    def _item_price_in_category(which_category, capacity)
      item_prices_in_category = self.upgrade_items.select { |item_price| item_price["categories"].find { |category| category["categoryCode"] == which_category } }
      item_prices_in_category.find { |ram_item| ram_item["item"]["capacity"].to_i == capacity}
    end

    ##
    # Constructs an upgrade order to order the given item price.
    # The order is built to execute immediately
    #
    def _order_upgrade_item!(upgrade_item_price)
      # put together an order
      upgrade_order = {
        'complexType' => 'SoftLayer_Container_Product_Order_Virtual_Guest_Upgrade',
        'virtualGuests' => [{'id' => self.id }],
        'properties' => [{'name' => 'MAINTENANCE_WINDOW', 'value' => Time.now.iso8601}],
        'prices' => [ upgrade_item_price ]
      }

      self.softlayer_client["Product_Order"].placeOrder(upgrade_order)
    end
  end #class VirtualServer
end