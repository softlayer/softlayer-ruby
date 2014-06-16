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

require 'rubygems'
require 'softlayer_api'
require 'pp'

# This example walks through the process putting together an order for
# a bare metal server using the SoftLayer::BareMetalServerOrder_Package class.
#
# The script uses verify_order to ensure the order constructed is
# valid. If you actually wanted to place an order for a server
# you would call place_order!

# Here is the product order code boiled down to a single routine without
# all the explaination found in the main body of code below. Skip down to
# that code for a better explaination of the steps involved in ordering
# a server.
def tl_dr_version
  client = SoftLayer::Client.new(
    # :username => "joecustomer"              # enter your username here
    # :api_key => "feeddeadbeefbadf00d..."   # enter your api key here
  )

  # Select a package
  quad_intel_package = SoftLayer::ProductPackage.package_with_id(client, 32)

  # Find required Categories and fill config_options with defaults
  config_options = {}
  required_categories = quad_intel_package.configuration.select { |category| category.required? }
  required_categories.each { |required_category| config_options[required_category.categoryCode] = required_category.default_option }

  # Provide a value for missing config categories
  config_options['server'] = 1417 # price id of Quad Processor Quad Core Intel 7420 - 2.13GHz (Dunnington) - 4 x 6MB / 8MB cache

  # With all the config options in place we can now construct the product order.
  server_order = SoftLayer::BareMetalServerOrder_Package.new(quad_intel_package, client)
  server_order.location = 'sng01'
  server_order.hostname = 'sample'
  server_order.domain = 'softlayerapi.org'
  server_order.configuration_options = config_options

  begin
    server_order.verify()
    puts "The Order appears to be OK"
  rescue Exception => e
    puts "Order didn't verify :-( #{e}"
  end
end

begin
  client = SoftLayer::Client.new(
    # :username => "joecustomer"              # enter your username here
    # :api_key => "feeddeadbeefbadf00d..."   # enter your api key here
  )

  # Servers are ordered from ProductPackages. We first get a list of all the
  # Bare Metal Server packages and print that list along with the package IDs
  puts "Bare Metal Server Packages:"
  packages = SoftLayer::ProductPackage.bare_metal_server_packages(client)
  packages.each { |package| puts "#{package.id}\t#{package.name}"}

  # For this example, we'll assume that we've selected the a package
  # with an id of 32 representing a "Quad Processor, Quad Core Intel"
  quad_intel_package = SoftLayer::ProductPackage.package_with_id(32, client)

  # Now we need to now what ProductItemCategories are required to
  # configure a server in that package. This code prints out a table
  # of the required category codes with a description of each
  puts "\nRequired Categories for '#{quad_intel_package.name}':"
  required_categories = quad_intel_package.configuration.select { |category| category.required? }
  max_code_length = required_categories.inject(0) { |max_code_length, category| [category.categoryCode.length, max_code_length].max }
  printf "%#{max_code_length}s\tCategory Description\n", "Category Code"
  printf "%#{max_code_length}s\t--------------------\n", "-------------"
  required_categories.each { |category| printf "%#{max_code_length}s\t#{category.name}\n", category.categoryCode}

  # We will need to provide values for each of the required category codes in our
  # configuration_options. Let's see what configuration options are available for
  # just one of the categories... Say 'os'
  os_category = quad_intel_package.category('os')
  config_options = os_category.configuration_options
  puts "\nConfiguration options in the 'os' category:"
  config_options.each { |option| printf "%5s\t#{option.description}\n", option.price_id }

  # For this example, we'll choose the first os option that contains the string 'CentOS 6'
  # in its description
  os_config_option = config_options.find { |option| option.description =~ /CentOS 6/ }

  # Let's begin choosing configuration_options with the default options in each required category
  # where they can be found. Read the description of ProductItemCategory#default_option carefully
  # to avoid surprises!
  config_options = {}
  required_categories.each { |required_category| config_options[required_category.categoryCode] = required_category.default_option }

  # print out descriptions of the the configuration options that were discovered
  puts "\nConfiguration with default options:"
  max_category_length = config_options.inject(0) { |max_category_length, pair| [pair[0].length, max_category_length].max }
  config_options.each { |category, config_option| printf "%#{max_category_length}s\t#{config_option ? config_option.description : 'no default'}\n", category }

  # Regardless of the default values... we know we want the os selection we discovered above:
  config_options['os'] = os_config_option

  # And we can customize the default config by providing selections for any config categories
  # we are interested in
  config_options.merge! ({
    'server' => 1417, # price id of Quad Processor Quad Core Intel 7420 - 2.13GHz (Dunnington) - 4 x 6MB / 8MB cache
    'port_speed' => 274 # 1 Gbps Public & Private Network Uplinks
  })

  # We have a configuration for the server, we also need a location for the new server.
  # The package can give us a list of locations. Let's print out that list
  puts "\nData Centers for '#{quad_intel_package.name}':"
  quad_intel_package.datacenter_options.each { |location| puts "\t#{location}"}

  # With all the config options in place we can now construct the product order.
  server_order = SoftLayer::BareMetalServerOrder_Package.new(quad_intel_package, client)
  server_order.datacenter = 'sng01'
  server_order.hostname = 'sample'
  server_order.domain = 'softlayerapi.org'
  server_order.configuration_options = config_options

  # The order should be complete... call verify_order to make sure it's OK.
  # you'll either get back a filled-out order, or you will get an
  # exception.  If you wanted to place the order, you would call 'place_order!' instead.
  begin
    server_order.verify()
    puts "The Order appears to be OK"
  rescue Exception => e
    puts "Order didn't verify :-( #{e}"
  end

rescue Exception => exception
  $stderr.puts "An exception occurred while trying to complete the SoftLayer API calls #{exception}"
end

