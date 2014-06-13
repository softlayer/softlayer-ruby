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
  
  # We can set the default client to be our client and that way 
  # we can avoid supplying it later
  SoftLayer::Client.default_client = SoftLayer::Client.new(
    # :username => "joecustomer"              # enter your username here
    # :api_key => "feeddeadbeefbadf00d..."   # enter your api key here
  )

  account = SoftLayer::Account.account_for_client()

  # grab a list of all the servers on the account.
  servers = account.servers

  # measure their fully qualified domain names so we can print a pretty table
  max_name_len = servers.inject(0) { |max_name, server| [max_name, server.fullyQualifiedDomainName.length].max }

  printf "%#{-max_name_len}s\tPrimary Public IP\n", "Server FQDN"
  printf "%#{-max_name_len}s\t-----------------\n", "-----------"

  servers.each do |server|
    ip_field = server.primary_public_ip ? server.primary_public_ip : "No Public Interface"
    printf "%#{-max_name_len}s\t#{ip_field}\n", server.fullyQualifiedDomainName
  end