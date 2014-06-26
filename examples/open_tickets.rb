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

# One way to provide a username and api key is to provide them
# as globals.
# $SL_API_USERNAME = "joecustomer"         # enter your username here
# $SL_API_KEY = "feeddeadbeefbadf00d..."   # enter your api key here

# The client constructed here must get it's credentials from somewhere
# In this script you might uncomment the globals above and assign your
# credentials there
SoftLayer::Client.default_client = SoftLayer::Client.new()

# The openTickets routine will pick up the default client established above.
open_tickets = SoftLayer::Ticket.open_tickets()

open_tickets.sort!{ |lhs, rhs| -(lhs.lastEditDate <=> rhs.lastEditDate) }
open_tickets.each do |ticket|
  printf "#{ticket.id} - #{ticket.title}"

  ticket.has_updates? ? printf("\t*\n") : printf("\n")
end
