#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

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
    # :attr_reader: cores
    # A count of the number of virtual processing cores allocated
    # to the server.
    sl_attr :cores, 'maxCpu'

    ##
    # :attr_reader: provision_date
    # The date the Virtual Server was provisioned.  This attribute can be
    # nil if the SoftLayer system has not yet finished provisioning the
    # server (consequently this attribute is used by the #wait_until_ready
    # method to determine when a server has been provisioned)
    sl_attr :provision_date, 'provisionDate'

    ##
    # :attr_reader:
    # The date the Virtual Server was provisioned.  This attribute can be
    # nil if the SoftLayer system has not yet finished provisioning the
    # server (consequently this attribute is used by the #wait_until_ready
    # method to determine when a server has been provisioned)
    #
    # DEPRECATION WARNING: This attribute is deprecated in favor of provision_date
    # and will be removed in the next major release.
    sl_attr :provisionDate

    ##
    # :attr_reader: active_transaction
    # The active transaction (if any) for this virtual server. Transactions
    # are used to make configuration changes to the server and only one
    # transaction can be active at a time.
    sl_attr :active_transaction, 'activeTransaction'

    ##
    # :attr_reader:
    # The active transaction (if any) for this virtual server. Transactions
    # are used to make configuration changes to the server and only one
    # transaction can be active at a time.
    #
    # DEPRECATION WARNING: This attribute is deprecated in favor of active_transaction
    # and will be removed in the next major release.
    sl_attr :activeTransaction

    ##
    # :attr_reader: block_devices
    # Storage devices attached to the server. Storage may be local
    # to the host running the Virtual Server, or it may be located
    # on the SAN
    sl_attr :block_devices, 'blockDevices'

    ##
    # :attr_reader:
    # Storage devices attached to the server. Storage may be local
    # to the host running the Virtual Server, or it may be located
    # on the SAN
    #
    # DEPRECATION WARNING: This attribute is deprecated in favor of block_devices
    # and will be removed in the next major release.
    sl_attr :blockDevices

    ##
    # :attr_reader: last_operating_system_reload
    # The last operating system reload transaction that was
    # run for this server. #wait_until_ready compares the
    # ID of this transaction to the ID of the active transaction
    # to determine if an OS reload is in progress.
    sl_attr :last_operating_system_reload, 'lastOperatingSystemReload'

    ##
    # :attr_reader:
    # The last operating system reload transaction that was
    # run for this server. #wait_until_ready compares the
    # ID of this transaction to the ID of the active transaction
    # to determine if an OS reload is in progress.
    #
    # DEPRECATION WARNING: This attribute is deprecated in favor of last_operating_system_reload
    # and will be removed in the next major release.
    sl_attr :lastOperatingSystemReload

    ##
    # Retrieve information about items that are available for upgrades.
    # :call-seq:
    #   upgrade_options(force_update=false)
    sl_dynamic_attr :upgrade_options do |resource|
      resource.should_update? do
        @upgrade_options == nil
      end

      resource.to_update do
        self.service.object_mask("mask[id,categories.categoryCode,item[id,capacity,units,attributes,prices]]").getUpgradeItemPrices(true)
      end
    end

    ##
    # IMMEDIATELY cancel this virtual server
    #
    def cancel!
      self.service.deleteObject()
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
    # The routine returns the instance of SoftLayer::ImageTemplate that is
    # created.  That image template will probably not be available immediately, however.
    # You may use the wait_until_ready routine of SoftLayer::ImageTemplate to
    # wait on it.
    #
    def capture_image(image_name, include_attached_storage = false, image_notes = '')
      image_notes = '' if !image_notes
      image_name = 'Captured Image' if !image_name

      disk_filter = lambda { |disk| disk['device'] == '0' }
      disk_filter = lambda { |disk| disk['device'] != '1' } if include_attached_storage

      disks = self.blockDevices.select(&disk_filter)

      self.service.createArchiveTransaction(image_name, disks, image_notes) if disks && !disks.empty?

      image_templates = SoftLayer::ImageTemplate.find_private_templates(:name => image_name)
      image_templates[0] if !image_templates.empty?
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

        reloading_os = has_active_transaction && has_os_reload && (self.last_operating_system_reload['id'] == self.active_transaction['id'])
        provisioned = has_sl_property?(:provisionDate) && ! self['provisionDate'].empty?

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
    # Retrieve the virtual server with the given server ID from the API
    #
    # The options parameter should contain:
    #
    # <b>+:client+</b> - The client used to connect to the API
    #
    # If no client is given, then the routine will try to use Client.default_client
    # If no client can be found the routine will raise an error.
    #
    # The options may include the following keys
    # * <b>+:object_mask+</b> (string) - A object mask of properties, in addition to the default properties, that you wish to retrieve for the server
    #
    def self.server_with_id(server_id, options = {})
      softlayer_client = options[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      vg_service = softlayer_client[:Virtual_Guest]
      vg_service = vg_service.object_mask(default_object_mask.to_sl_object_mask)

      if options.has_key?(:object_mask)
        vg_service = vg_service.object_mask(options[:object_mask])
      end

      server_data = vg_service.object_with_id(server_id).getObject()

      return VirtualServer.new(softlayer_client, server_data)
    end

    ##
    # Retrieve a list of virtual servers from the account.
    #
    # The options parameter should contain:
    #
    # <b>+:client+</b> - The client used to connect to the API
    #
    # If no client is given, then the routine will try to use Client.default_client
    # If no client can be found the routine will raise an error.
    #
    # You may filter the list returned by adding options:
    # * <b>+:hourly+</b>     (boolean)      - Include servers billed hourly in the list
    # * <b>+:monthly+</b>    (boolean)      - Include servers billed monthly in the list
    # * <b>+:tags+</b>       (string/array) - an array of strings representing tags to search for on the instances
    # * <b>+:cpus+</b>       (int/array)    - return virtual servers with the given number of (virtual) CPUs
    # * <b>+:memory+</b>     (int/array)    - return servers with at least the given amount of memory (in MB. e.g. 4096 = 4GB)
    # * <b>+:hostname+</b>   (string/array) - return servers whose hostnames match the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:domain+</b>     (string/array) - filter servers to those whose domain matches the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:local_disk+</b> (boolean)      - include servers that do, or do not, have local disk storage
    # * <b>+:datacenter+</b> (string/array) - find servers whose short data center name (e.g. dal05, sjc01) matches the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:nic_speed+</b>  (int/array)    - include servers with the given nic speed (in Mbps, usually 10, 100, or 1000)
    # * <b>+:public_ip+</b>  (string/array) - return servers whose public IP address matches the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:private_ip+</b> (string/array) - same as :public_ip, but for private IP addresses
    #
    # Additionally you may provide options related to the request itself:
    # * <b>+:object_mask+</b> (string) - A object mask of properties, in addition to the default properties, that you wish to retrieve for the servers
    # * <b>+:result_limit+</b> (hash with :limit, and :offset keys) - Limit the scope of results returned.
    #
    def self.find_servers(options_hash = {})
      softlayer_client = options_hash[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      if(options_hash.has_key? :object_filter)
        object_filter = options_hash[:object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        object_filter = ObjectFilter.new()
      end

      option_to_filter_path = {
        :cores      => "virtualGuests.maxCpu",
        :memory     => "virtualGuests.maxMemory",
        :hostname   => "virtualGuests.hostname",
        :domain     => "virtualGuests.domain",
        :local_disk => "virtualGuests.localDiskFlag",
        :datacenter => "virtualGuests.datacenter.name",
        :nic_speed  => "virtualGuests.networkComponents.maxSpeed",
        :public_ip  => "virtualGuests.primaryIpAddress",
        :private_ip => "virtualGuests.primaryBackendIpAddress",
        :tags       => "virtualGuests.tagReferences.tag.name"
      }

      if options_hash.has_key?(:local_disk) then
        options_hash[:local_disk] = options_hash[:local_disk] ? 1 : 0
      end

      # For each of the options in the option_to_filter_path map, if the options hash includes
      # that particular option, add a clause to the object filter that filters for the matching
      # value
      option_to_filter_path.each do |option, filter_path|
        object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option])} if options_hash[option]
      end

      required_properties_mask = 'mask.id'

      account_service = softlayer_client[:Account]
      account_service = account_service.object_filter(object_filter) unless object_filter.empty?
      account_service = account_service.object_mask(default_object_mask.to_sl_object_mask)

      if options_hash.has_key? :object_mask
        account_service = account_service.object_mask(options_hash[:object_mask])
      end

      if options_hash.has_key?(:result_limit)
        offset = options[:result_limit][:offset]
        limit = options[:result_limit][:limit]

        account_service = account_service.result_limit(offset, limit)
      end

      case
      when options_hash[:hourly] && options_hash[:monthly]
        virtual_server_data = account_service.getVirtualGuests()
      when options_hash[:hourly]
        virtual_server_data = account_service.getHourlyVirtualGuests()
      when options_hash[:monthly]
        virtual_server_data = account_service.getMonthlyVirtualGuests()
      else
        virtual_server_data = account_service.getVirtualGuests()
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
    # Returns the SoftLayer Service that represents calls to this object
    # For VirtualServers the service is +SoftLayer_Virtual_Guest+ and
    # addressing this object is done by id.
    def service
      return softlayer_client[:Virtual_Guest].object_with_id(self.id)
    end
  end #class VirtualServer
end
