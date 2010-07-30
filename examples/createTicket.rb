# Copyright (c) 2010, SoftLayer Technologies, Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#  * Neither SoftLayer Technologies, Inc. nor the names of its contributors may
#    be used to endorse or promote products derived from this software without
#    specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

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
