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

$SL_API_USERNAME = "joecustomer"         # enter your username here
$SL_API_KEY = "feeddeadbeefbadf00d..."   # enter your api key here

softlayer_client = SoftLayer::Client.new()

# use an account service to get a list of the open tickets and print their
# IDs and titles
account_service = softlayer_client.service_named("Account")

open_tickets = account_service.getOpenTickets
open_tickets.each { |ticket| puts "#{ticket['id']} - #{ticket['title']}" }

# Now use the ticket service to get a each ticket (by ID) and a subset of the
# information known about it. We've already collected this information above,
# but this will demonstrate using an object mask to filter the results from
# the server.
ticket_service = softlayer_client["Ticket"]
open_tickets.each do |ticket|
  begin
    pp ticket_service.object_with_id(ticket["id"]).object_mask("mask[id,title,createDate,modifyDate,assignedUser[id,username,email]]").getObject
  rescue Exception => exception
    puts "exception #{exception}"
  end
end

