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
  #
  # This class is used to order a Bare Metal Instances.  Please see
  # the class +BareMetalServerOrder+ to order a bare metal server.
  #
  # Ordering hardware is complex. Please see the documentation for
  # +BareMetalOrder+ for more information about ordering hardware servers.
  #
  class BareMetalInstanceOrder < BareMetalOrder
    # A single package is used to create Bare Metal Instances
    # This returns that package ID.
    attr_reader :package_id

    # Boolean, If true the order will try to create an instance that is
    # billed hourly.  Otherwise it will create a monthly billed instance
    # (which is the default)
    attr_accessor :hourly

    def package_id
      if nil == @package_id
        package = SoftLayer::BareMetalInstanceOrder.bare_metal_instance_package(@softlayer_client)
        @package_id = package[:package_id]
      end

      @package_id
    end

    # Return the bare metal instance package.  There should be only one.
    def self.bare_metal_instance_package(client)
      filter = SoftLayer::ObjectFilter.build('type.keyName') { is('BARE_METAL_CORE') }
      packages = client['Product_Package'].object_filter(filter).object_mask('mask[id, name, description]').getAllObjects

      # At the time of this writing, there is only one BARE_METAL_CORE package.
      # If there are ever more than one, then this logic will have to be updated
      # to select the "right" one
      bare_metal_package = packages.first

      { :package_id => bare_metal_package['id'],
        :package_name => bare_metal_package['name'],
        :package_description => bare_metal_package['description'] }
    end #bare_metal_server_packages

    protected

    def order_hash
      order_hash = super
      order_hash['useHourlyPricing'] = !!@hourly
      order_hash['hardware']['bareMetalInstanceFlag'] = true
      order_hash
    end
  end
end # SoftLayer