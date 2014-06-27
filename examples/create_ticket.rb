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

softlayer_client = SoftLayer::Client.new(
# :username => "joecustomer"              # enter your username here
# :api_key => "feeddeadbeefbadf00d..."   # enter your api key here
)

begin
  # To create a ticket we have to assign the ticket to some user so
  # assign our new ticket to the current user
  account = SoftLayer::Account.account_for_client(softlayer_client)
  account_user = account.service.getCurrentUser
  my_user_id = account_user["id"]

  # We also need a subject for the ticket. Subjects are specified by id
  # This code prints out a table of all the ticket subjects with their
  # ids:
  ticket_subjects = SoftLayer::Ticket.ticket_subjects(softlayer_client)
  ticket_subjects.each do |subject|
    puts "#{subject['id']}\t#{subject['name']}"
  end

  # For this example we'll use 'Public Network Question' as the subject.  That's id 1022
  public_network_question_id = 1022

  # A title is optional, but we'll provide one and we offer the body of the ticket
  # remember to pass the client to create_standard_ticket
  new_ticket = SoftLayer::Ticket.create_standard_ticket(
    :client => softlayer_client,
    :title => "This is a test ticket, please simply close it",
    :body => "This test ticket was created to test the Ruby API client.  Please ignore it.",
    :subject_id => public_network_question_id,
    :assigned_user_id => my_user_id
  )

  puts "Created a new ticket : #{new_ticket.id} - #{new_ticket.title}"

  # we can also add an update to the ticket:
  new_ticket.update("This is a ticket update sent from the Ruby library")

rescue Exception => exception
  $stderr.puts "An exception occurred while trying to complete the SoftLayer API calls #{exception}"
end
