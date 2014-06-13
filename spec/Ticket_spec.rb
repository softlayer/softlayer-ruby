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

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

require 'spec_helper'

describe SoftLayer::Ticket do
  before (:each) do
    SoftLayer::Ticket.instance_eval { @ticket_subjects = nil }
  end

	it "retrieves ticket subjects from API once" do
    fakeTicketSubjects = fixture_from_json("ticket_subjects")

	  mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key=> 'fakekey')
    allow(mock_client).to receive(:[]) do |service_name|
      expect(service_name).to eq "Ticket_Subject"

      mock_service = SoftLayer::Service.new("SoftLayer_Ticket_Subject", :client => mock_client)
      expect(mock_service).to receive(:getAllObjects).once.and_return(fakeTicketSubjects)
      expect(mock_service).to_not receive(:call_softlayer_api_with_params)

      mock_service
    end

    expect(SoftLayer::Ticket.ticket_subjects(mock_client)).to be(fakeTicketSubjects)

    # call for the subjects again which should NOT re-request them from the client
    # (so :getAllObjects on the service should not be called again)
    expect(SoftLayer::Ticket.ticket_subjects(mock_client)).to be(fakeTicketSubjects)
	end

  it "raises an error if you try to get ticket subjects with no client" do
    SoftLayer::Client.default_client = nil
    expect {SoftLayer::Ticket.ticket_subjects() }.to raise_error
  end

  it "identifies itself with the ticket service" do
    fake_ticket_data = fixture_from_json("test_tickets").first

	  mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key=> 'fakekey')
    allow(mock_client).to receive(:[]) do |service_name|
      expect(service_name).to eq "Ticket"
      mock_service = SoftLayer::Service.new("SoftLayer_Ticket", :client => mock_client)

      # mock out call_softlayer_api_with_params so the service doesn't actually try to
      # communicate with the api endpoint
      allow(mock_service).to receive(:call_softlayer_api_with_params)

      mock_service
    end

    fake_ticket = SoftLayer::Ticket.new(mock_client, fake_ticket_data)
    ticket_service = fake_ticket.service
    expect(ticket_service.server_object_id).to eq(12345)
    expect(ticket_service.target.service_name).to eq "SoftLayer_Ticket"
  end
end