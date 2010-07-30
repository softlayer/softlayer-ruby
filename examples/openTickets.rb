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

$SL_API_USERNAME = "joecustomer"         # enter your username here
$SL_API_KEY = "feeddeadbeefbadf00d..."   # enter your api key here

# use an account service to get a list of the open tickets and print their 
# IDs and titles
account_service = SoftLayer::Service.new("SoftLayer_Account")

open_tickets = account_service.getOpenTickets
open_tickets.each { |ticket| puts "#{ticket['id']} - #{ticket['title']}" }

# Now use the ticket service to get a each ticket (by ID) and a subset of the
# information known about it. We've already collected this information above,
# but this will demonstrate using an object mask to filter the results from
# the server.
ticket_service = SoftLayer::Service.new("SoftLayer_Ticket")
open_tickets.each do |ticket|
  begin
    pp ticket_service.object_with_id(ticket["id"]).object_mask( "id", "title", "createDate", "modifyDate", { "assignedUser" => ["id", "username", "email"] }).getObject
  rescue Exception => exception
    puts "exception #{e}"
  end
end
