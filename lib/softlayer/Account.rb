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

module SoftLayer
  class Account < SoftLayer::ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader:
    # The company name of the primary contact
    sl_attr :companyName

    ##
    # :attr_reader:
    # The given name name of the primary contact
    sl_attr :firstName

    ##
    # :attr_reader:
    # The surname of the primary contact
    sl_attr :lastName

    ##
    # :attr_reader:
    # The first address line for the primary contact's address
    sl_attr :address1

    ##
    # :attr_reader:
    # The second address line (if any, may be nil) for the primary contact's address
    sl_attr :address2

    ##
    # :attr_reader:
    # The city stored as part of the primary contact's address
    sl_attr :city

    ##
    # :attr_reader:
    # The two character abbreviation for the state, province, or other similar national
    # division that is part of the address of the primary contact.  For addresses
    # outside of the US and Canada, where there may not be an equivalent to a state,
    # this may be 'NA' (for not applicable)
    sl_attr :state

    ##
    # :attr_reader:
    # The country stored as part of the primary contact's address
    sl_attr :country

    ##
    # :attr_reader:
    # The postal code (in the US, aka. zip code) of the primary contact's address
    sl_attr :postalCode

    ##
    # :attr_reader:
    # The office phone nubmer listed for the primary contact
    sl_attr :officePhone

    ##
    # The Bare Metal Servers (physical hardware) associated with the
    # account. Unless you force these to update, they will be refreshed every
    # five minutes.
    # :call-seq:
    #   bare_metal_servers(force_update=false)
    sl_dynamic_attr :bare_metal_servers do |bare_metal|
      bare_metal.should_update? do
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
    # :call-seq:
    #   virtual_servers(force_update=false)
    sl_dynamic_attr :virtual_servers do |virtual_servers|
      virtual_servers.should_update? do
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
    # "recently". These refresh every 5 minutes.
    # :call-seq:
    #   tickets(force_update=false)
    sl_dynamic_attr :tickets do |tickets|
      tickets.should_update? do
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
    # Get a list of the servers for the account. The list returned
    # includes both bare metal and virtual servers
    def servers
      return self.bare_metal_servers + self.virtual_servers
    end
  end
end