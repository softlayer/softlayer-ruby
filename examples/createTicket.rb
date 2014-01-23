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

# We're creating more than one service so we'll use the globals to establish
# the username and API key.
$SL_API_USERNAME = "joecustomer"         # enter your username here
$SL_API_KEY = "feeddeadbeefbadf00d..."   # enter your api key here

begin
  # use an account service to get the account ID of my account
  account_service = SoftLayer::Service.new("SoftLayer_Account")
  my_account_id = account_service.getCurrentUser['id']

  # Use a ticket service to create a standard support ticket, assigned to me.
  ticket_service = SoftLayer::Service.new("SoftLayer_Ticket")
  new_ticket = ticket_service.createStandardTicket(
                  {
                    "assignedUserId" => my_account_id,
                    "subjectId" => 1022,
                    "notifyUserOnUpdateFlag" => true
                  },
                  "This is a test ticket created from a Ruby client")

  puts "Created a new ticket : #{new_ticket['id']} - #{new_ticket['title']}"

  # add an update to the newly created ticket.
  pp ticket_service.object_with_id(new_ticket['id']).edit(nil, "This is a ticket update sent from the Ruby library")
rescue Exception => exception
  $stderr.puts "An exception occurred while trying to complete the SoftLayer API calls #{exception}"
end
