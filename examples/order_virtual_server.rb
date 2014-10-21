$LOAD_PATH << File.join(File.dirname(__FILE__), "../lib")

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

begin
  # This sample walks through the creation of a Virtual Server.
  # It explores techniques for discovering what configuration options
  # exist, puts together an order, then sends that order to
  # SoftLayer for verification.

  client = SoftLayer::Client.new(
    # :username => "joecustomer"              # enter your username here
    # :api_key => "feeddeadbeefbadf00d..."   # enter your api key here
  )

  # We begin by creating a VirtualServerOrder and filling out the hostname and domain
  # attributes.
  server_order = SoftLayer::VirtualServerOrder.new(client)
  server_order.hostname = "server1"
  server_order.domain = "ruby-api-test.org"

  # We must tell the system in which datacenter we want our server created
  # We can ask the class to give us a list of options:
  puts SoftLayer::VirtualServerOrder.datacenter_options(client).inspect

  # The list will look something like ["ams01", "dal01", "dal05",...
  # Let's put our server in the 'dal05' (Dallas 5) datacenter
  server_order.datacenter = SoftLayer::Datacenter.datacenter_named 'dal05', client

  # The order must know how many computing cores we want in our virtual
  # server.  Again we can ask the class for options.  The result will
  # be something like [1, 2, 4, 8, 12, 16]
  # 2 sounds like a good number of cores for our simple server
  puts SoftLayer::VirtualServerOrder.core_options(client).inspect
  server_order.cores = 2

  # We must indicate how much memory the virtual server should have.
  # Again we can query for options and select a good value
  puts SoftLayer::VirtualServerOrder.memory_options(client).inspect
  server_order.memory = 2 #GB

  # Similarly we can choose an operating system for the server:
  puts SoftLayer::VirtualServerOrder.os_reference_code_options(client).inspect
  server_order.os_reference_code = 'CENTOS_6_64'

  # Finally, in spite of the fact that our server is simple, we want it
  # to have a blazing fast connection speed.  Let's look at the options and choose
  # the fastest! (it's probably 1 Gbps)
  server_order.max_port_speed = SoftLayer::VirtualServerOrder.max_port_speed_options(client).max

  # The server order is now complete. This sample will ask it to verify itself with the
  # SoftLayer ordering system, but a simple change from verify to place_order! would ask
  # the system to provision the server (and charge it to our account)
  begin
    server_order.verify
    puts "The server order is OK"
  rescue Exception => e
    puts "The server order failed verification :-( -- #{e}"
  end
rescue Exception => exception
  $stderr.puts "An exception occurred while trying to complete the SoftLayer API calls #{exception}"
end

