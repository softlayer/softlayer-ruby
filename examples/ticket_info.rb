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

ticket_service = SoftLayer::Service.new("SoftLayer_Ticket",
  :username => "joecustomer",              # enter your username here
  :api_key => "feeddeadbeefbadf00d...")    # enter your api key here

begin
  ticket_ref = ticket_service.object_with_id(1683973)

  ticket = ticket_ref.object_mask({"updates" => ["entry", "createDate"]}, 
                                  "assignedUserId", 
                                  {"attachedHardware" => "datacenter"}).getObject
  pp ticket
rescue Exception => exception
	puts "Unable to retrieve the ticket"
end

# update the ticket
begin
  updates = ticket_ref.addUpdate({"entry" => "An update from the Ruby client!"})
  puts "Update ticket 123456. The new update's id is #{updates[0]['id']}"
rescue Exception => exception
	puts "Unable to update the ticket: #{exception}"
end
