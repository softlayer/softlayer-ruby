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
  class VirtualServer < Server

    ##
    # Cancel this virtual server immediately and delete all its data.
    #
    def cancel!
      self.service.object_with_id(self.id).deleteObject()
    end

    ##
    # Returns the SoftLayer Service used to work with instances of this class.  For Virtual Servers that is +SoftLayer_Virtual_Guest+
    def service
      return softlayer_client["Virtual_Guest"]
    end

    def wait_until_ready(max_trials, wait_for_transactions = false, seconds_between_tries = 2)
      # pessimistically assume the server is not ready
      num_trials = 0
      begin
        self.refresh_details()

        last_os_reload = has_sl_property? :lastOperatingSystemReload
        active_transaction = has_sl_property? :activeTransaction

        reloading_os = active_transaction && last_os_reload && (self.lastOperatingSystemReload['id'] == self.activeTransaction['id'])
        provisioned = has_sl_property? :provisionDate

        # a server is ready when it is provisioned, not reloading the OS and
        # (if the user has asked us to wait on other transactions) when there are
        # no active transactions.
        ready = provisioned && !reloading_os && (!wait_for_transactions || !active_transaction)

        num_trials = num_trials + 1

        sleep(seconds_between_tries) if !ready && (num_trials <= max_trials)
      end until ready || (num_trials >= max_trials)

      ready
    end

    ##
    # Returns the default object mask used when fetching servers from the API when an
    # explicit object mask is not provided.
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
    # Retrive the virtual server with the given server ID from the API
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
    # * <b>+:object_mask+</b> (string, hash, or array) - The object mask of properties you wish to receive for the items returned If not provided, the result will use the default object mask
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
  end #class VirtualServer
end