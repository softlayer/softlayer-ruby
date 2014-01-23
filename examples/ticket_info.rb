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
