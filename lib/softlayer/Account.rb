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

module SoftLayer
  class Account < SoftLayer::ModelBase
    include ::SoftLayer::ModelResource

    ##
    # The bare metal (or Hardware) servers associated with the
    # account. Unless you force these to update, they will be refreshed every
    # five minutes.
    softlayer_resource :bare_metal_servers do |bare_metal|
      bare_metal.should_update_if do
        @last_bare_metal_update ||= Time.at(0)
        (Time.now - @last_bare_metal_update) > 5 * 60  # update every 5 minutes
      end

      bare_metal.to_update do
        @last_bare_metal_update = Time.now
        BareMetalServer.find_servers(self.softlayer_client)
      end
    end

    ##
    # The virtual servers (aka. CCIs or Virtual_Guests) associated with the
    # account. Unless you force these to update, they will be refreshed every
    # five minutes.
    softlayer_resource :virtual_servers do |virtual_servers|
      virtual_servers.should_update_if do
        @last_virtual_server_update ||= Time.at(0)
        (Time.now - @last_virtual_server_update) > 5 * 60  # update every 5 minutes
      end

      virtual_servers.to_update do
        @last_virtual_server_update = Time.now
        VirtualServer.find_servers(self.softlayer_client)
      end
    end

    ##
    # The tickets resource consists of all open tickets, and tickets closed
    # "recently". These refresh every 5 minutes
    softlayer_resource :tickets do |tickets|
      tickets.should_update_if do
        @last_ticket_update ||= Time.at(0)
        (Time.now - @last_ticket_update) > 5 * 60 #update every 5 minutes
      end

      tickets.to_update do
        @last_ticket_update = Time.now

        open_ticket_data = self.softlayer_client["Account"].object_mask(Ticket.default_object_mask).getOpenTickets()
        recently_closed_data = self.softlayer_client["Account"].object_mask(Ticket.default_object_mask).getTicketsClosedInTheLastThreeDays()

        open_tickets = open_ticket_data.collect { |ticket_data| Ticket.new(self.softlayer_client, ticket_data) }
        closed_tickets = recently_closed_data.collect { |ticket_data| Ticket.new(self.softlayer_client, ticket_data) }

        open_tickets + closed_tickets
      end
    end

    ##
    # Using the login credentials in the client, retrieve
    # the account associated with those credentials.
    #
    def self.account_for_client(softlayer_client)
      account_service = softlayer_client['Account']
      network_hash = account_service.getObject()
      new(softlayer_client, network_hash)
    end

    ##
    # The +account_id+ property is simply an alias for the SLDN id of the account object.
    def account_id
      @sl_hash[:id]
    end

    ##
    # Get a list of the servers for the account. The list returned
    # includes both bare metal and virtual servers
    def servers
      return self.bare_metal_servers + self.virtual_servers
    end
  end
end