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
  ##
  #
  # An order for a new Bare Metal Server or Bare Metal Instance
  #
  # This is an abstract class and you should use +BareMetalServerOrder+ or +BareMetalInstanceOrder+
  # to ensure you get the correct flavor of hardware.
  #
  # Placing an order for new Bare Metal, both Instances and Servers, requires you to provide
  # all the configuration options for the new server.
  #
  # You first select the chassis, or base configuration for the server.  This is done
  # by selecting a Package ID. If you are ordering a Bare Metal Server, you must
  # determine the package ID for the kind of server you want to create. You can retrieve a list
  # available packages by calling +BareMetalServerOrder.bare_metal_server_packages+
  #
  # If you are creating a Bare Metal Instance, the package ID is fixed by the system
  #
  # An example of calling +BareMetalServerOrder.bare_metal_server_packages+:
  #
  #     client = SoftLayer::Client.new()
  #     package_info = SoftLayer::BareMetalServerOrder.bare_metal_server_packages(client)
  #
  # +package_info+ might begin with items like this:
  #
  #     [{:package_id=>32,
  #       :package_name=>"Quad Processor, Quad Core Intel",
  #       :package_description=>
  #         "<div class=\"PageTopicSubHead\">Quad Processor Multi-core Servers</div>"},
  #      {:package_id=>35,
  #       :package_name=>"Dual Xeon (Dual Core) Woodcrest/Cloverton - OUTLET",
  #       :package_description=>
  #         "<div class=\"PageTopicSubHead\">dual processor multi core</div>"},
  #      ...
  #
  # The set of available packages and the information found in the packages changes infrequently
  # For performance reasons, you may wish to save off the package_info and re-use it, refreshing
  # the information only on occasion.
  #
  # For the sake of an example, let's assume you wish to order a Bare Metal Server that is
  # a Quad Processor, Quad Core Intel server. The list above shows that has a +:package_id+ of 32.
  #
  # Once you have the base configuration in the form of a package id, the next step is
  # to select the values for configuration options in that package. Configuration options
  # are devided into categories; each category has a category code. Category codes are simply
  # strings (e.g. 'os', or 'ram').
  #
  # Some categories are *required* and a valid order must contain a selection for that category.
  #
  # For each category, you will identify the option you have
  # selected for your new server by indicating that option's +:price_id+.
  #
  # To determine what categories exist for the servers in a package, to find out what categories
  # are required, and to list the configuration options available in each category you use the
  # routine +BareMetalOrder.bare_metal_order_options+.
  #
  # For example, using package 32 (the quad processor selection above)
  # we may use +BareMetalOrder.bare_metal_order_options+ to find out which
  # categories of options are required for servers in that package:
  #
  #    client = SoftLayer::Client.new()
  #    package_info = SoftLayer::BareMetalOrder.bare_metal_order_options(client, 32)
  #    required_categories = package_info[:categories].select { |key, value| value[:is_required] }.keys
  #
  # This yields +required_categories+, an array:
  #
  #     ["server", "os", "ram", "disk_controller", "disk0", "bandwidth", "port_speed", "remote_management",
  #       "pri_ip_addresses", "power_supply", "monitoring", "notification", "response", "vpn_management",
  #       "vulnerability_scanner"]
  #
  # and a valid order for a server in package 32 would include selections for each of these required
  # categories.
  #
  # Let's examine just one of those categories, find out what options are available, and find the
  # +:price_id+ for each option
  #
  #     os_category = package_info[:categories]['os']
  #     os_options = os_category[:items].collect { |item| [item[:price_id], item[:description]]}
  #
  # +os_options+ contains an array with entries like:
  #
  #     [[13942, "CentOS 6.x (64 bit)"],
  #      [13936, "CentOS 6.x (32 bit)"],
  #      [683, "CentOS 5.x (64 bit)"],
  #      ...
  #
  # That means that if we wish to configure the OS for our server to be CentOS 6.x (64 bit), we would
  # include the price id +13942+ for the +'os'+ category code in our +configuration_options+:
  #
  #     my_config = { 'os' => 13942, ... }
  #
  # The +configuration_options+ would also include entries for all the other required categories
  # (as well as selections for any optional categories).
  #
  # Another important property for the order is the data center, or +location+, where the server will
  # reside.  For a given package, +BareMetalOrder.bare_metal_order_options+ also provides a
  # list of available locations:
  #
  #      available_locations = package_info[:locations]
  #
  # +available_locations+ would be an array:
  #
  #     [{:delivery_information=>"Typical Installation time is 2 to 4 hours.",
  #       :keyname=>"FIRST_AVAILABLE",
  #       :long_name=>"First Available"},
  #      {:delivery_information=>"Typical Installation time is 2 to 4 hours.",
  #       :keyname=>"WASHINGTON_DC",
  #       :long_name=>"WDC01 - Washington, DC - East Coast U.S."},
  #      {:delivery_information=>"Typical Installation time is 2 to 4 hours.",
  #       :keyname=>"SANJOSE",
  #       ...
  #
  # The +location+ property of the order should be set to one of values found in the :keyname field of
  # the locations in the array.
  #
  # Putting this all together, a complete order might look like this:
  #
  #     client = SoftLayer::Client.new()
  #     my_order = SoftLayer::BareMetalServerOrder.new(client)
  #     my_order.package_id = 32
  #     my_order.hostname = "sthompson-ruby-api"
  #     my_order.domain = "softlayer.com"
  #     my_order.location = "DALLAS05"
  #     my_order.configuration_options = {
  #       'server' => 1417, # "Quad Processor Quad Core Intel 7420 - 2.13GHz (Dunnington) - 4 x 6MB / 8MB cache "
  #       'os' => 13942, # "CentOS 6.x (64 bit)"
  #       'ram' => 1016, # "16 GB FB-DIMM Registered 533/667"
  #       'disk_controller' => 876, # "Non-RAID"
  #       'disk0' => 1267, # "500GB SATA II"
  #       'bandwidth' => 342, # "20000 GB Bandwidth",
  #       'port_speed' => 273, # "100 Mbps Public & Private Network Uplinks"
  #       'remote_management' => 906, # "Reboot / KVM over IP"
  #       'pri_ip_addresses' => 21, # "1 IP Address"
  #       'power_supply' => 792, # "Redundant Power Supply"
  #       'monitoring' => 55, # "Host Ping"
  #       'notification' => 57, # "Email and Ticket"
  #       'response' => 58, # "Automated Notification"
  #       'vpn_management' => 420, # "Unlimited SSL VPN Users & 1 PPTP VPN User per account"
  #       'vulnerability_scanner' => 418 # "Nessus Vulnerability Assessment & Reporting"
  #     }
  #
  #     my_order.verify()
  #
  class BareMetalOrder
    #--
    # Required Attributes
    # -------------------
    # The following attributes are required in order to successfully order
    # a bare metal server.  In addition, the configuration_options must include
    # selections for all the required configuration categories in the package
    # identified by the package_id.
    #++

    # String, The location +:keyname+ identifying where the server will be created
    attr_accessor :location

    # String, The hostname to assign to the new server
    attr_accessor :hostname

    # String, The domain (i.e. softlayer.com) for the new server
    attr_accessor :domain

    # Hash mapping configuration catgories to price ids, The configuration options for this server
    attr_accessor :configuration_options

    # --
    # Optional attributes
    # ++

    # Fixnum, The id of the public VLAN this server should join
    attr_accessor :public_vlan_id

    # Fixnum, The id of the private VLAN this server should join
    attr_accessor :private_vlan_id

    # String, the URI of a post provisioning script to run on this server once it is created
    attr_accessor :post_provision_uri

    # Array of Strings, The SSH keys to add to the root user's account.
    attr_accessor :ssh_keys

    # Create a new order that works through the given client.
    def initialize(client)
      @softlayer_client = client
    end

    # Ask the SoftLayer API to verify the given order.  The method will either succeed
    # and return a completed order form, or will raise an exception
    def verify()
      return @softlayer_client['Product_Order'].verifyOrder(order_hash)
    end

    # Place an order for a new hardware server
    def place_order!()
      return @softlayer_client['Product_Order'].placeOrder(order_hash)
    end

    protected

    # Constructs the order template that will be passed to place_order! or verify
    def order_hash()
      # Configure information about the hardware itself though a hardware object template
      template = {
        'hostname' => @hostname,
        'domain' => @domain,
        'bareMetalInstanceFlag' => false
      }

      template['primaryNetworkComponent'] = { "networkVlan" => { "id" => @public_vlan_id.to_i } } if @public_vlan_id
      template['primaryBackendNetworkComponent'] = { "networkVlan" => {"id" => @private_vlan_id } } if @private_vlan_id

      order = {
        'location' => @location,
        'packageId' => @package_id,
        'hardware' => [template]
      }

      order['provisionScripts'] = [ @post_provision_uri ] if @post_provision_uri
      order['sshKeys'] = [{'sshKeyIds' => @ssh_keys}] if @ssh_keys

      order['prices'] = @configuration_options.collect { |category_code, price_id| {'id' => price_id } }

      order
    end

  end
end # SoftLayer