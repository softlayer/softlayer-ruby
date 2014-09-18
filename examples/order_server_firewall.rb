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

# This is the id of the server you want to protect with a firewall.
# The server can be Bare Metal or Virtual.  It should have a public
# network interface, and it should not already have a firewall on it.
server_id = 257696 # 12345

# In this example, we assume this is a Bare Metal Server
is_virtual_server = false

# Work with the SoftLayer API begins with a client.  By setting
# the "default" client we avoid having to specify the client repeatedly
# in calls that follow.
SoftLayer::Client.default_client = SoftLayer::Client.new(
  # :username => "joecustomer"              # enter your username here
  # :api_key => "feeddeadbeefbadf00d..."   # enter your api key here
)

# in this case we go straight to the appropriate class to find the server
# an alternative might be to create the account for this client and
# search the list of servers for the one with the appropriate ID.
if is_virtual_server
  server = SoftLayer::VirtualServer.server_with_id(server_id)
else
  server = SoftLayer::BareMetalServer.server_with_id(server_id)
end

# Create an instance of SoftLayer::ServerFirewallOrder
order = SoftLayer::ServerFirewallOrder.new(server)

begin
  # this example calls order.verify which will build the order, submit it 
  # to the network API, and will throw an exception if the order is
  # invalid.
  order.verify()
  puts "Firewall order is good for #{server.fullyQualifiedDomainName}"
rescue => exception
  puts "Firewall order failed for #{server.fullyQualifiedDomainName} because #{exception}"
end