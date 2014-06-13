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

describe SoftLayer::Account do
	it "should exist" do
		expect(SoftLayer::Account).to_not be_nil
	end

  it "knows its id" do
    mock_client = SoftLayer::Client.new(:username => "fake_user", :api_key => "BADKEY")
    test_account = SoftLayer::Account.new(mock_client, "id" => 232279, "firstName" => "kangaroo")
    expect(test_account.id).to eq(232279)
  end

  it "identifies itself with the Account service" do
    mock_client = SoftLayer::Client.new(:username => "fake_user", :api_key => "BADKEY")
    allow(mock_client).to receive(:[]) do |service_name|
      expect(service_name).to eq "Account"
      mock_service = SoftLayer::Service.new("SoftLayer_Account", :client => mock_client)

      # mock out call_softlayer_api_with_params so the service doesn't actually try to
      # communicate with the api endpoint
      allow(mock_service).to receive(:call_softlayer_api_with_params)

      mock_service
    end

    fake_account = SoftLayer::Account.new(mock_client, "id" => 12345)
    expect(fake_account.service.server_object_id).to eq(12345)
    expect(fake_account.service.target.service_name).to eq "SoftLayer_Account"
  end

  it "should allow the user to get the default account for a service" do
    test_client = double("mockClient")
    allow(test_client).to receive(:[]) do |service_name|
      expect(service_name).to eq "Account"

      test_service = double("mockService")
      allow(test_service).to receive(:getObject) do
        { "id" => "232279", "firstName" => "kangaroo" }
      end

      test_service
    end

    test_account = SoftLayer::Account.account_for_client(test_client)
    expect(test_account.softlayer_client).to eq(test_client)
    expect(test_account.id).to eq("232279")
    expect(test_account.firstName).to eq("kangaroo")
  end

  describe "softlayer attributes" do
    let (:test_account) {
      mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "fake_api_key")
      SoftLayer::Account.new(mock_client, fixture_from_json("test_account"))
    }

    it "exposes a great many softlayer attributes" do
      expect(test_account.companyName).to eq "UpAndComing Software"
      expect(test_account.firstName).to eq "Don "
      expect(test_account.lastName).to eq "Joe"
      expect(test_account.address1).to eq "123 Main Street"
      expect(test_account.address2).to eq nil
      expect(test_account.city).to eq "Anytown"
      expect(test_account.state).to eq "TX"
      expect(test_account.country).to eq "US"
      expect(test_account.postalCode).to eq "778899"
      expect(test_account.officePhone).to eq "555.123.4567"
    end
  end

  describe "relationship to servers" do
    it "should respond to a request for servers" do
      fixture_account_data = fixture_from_json("test_account")
      fixture_bare_metal_data = fixture_from_json("test_bare_metal.json")
      fixture_virtual_server_data = fixture_from_json("test_virtual_servers")

      mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "fake_api_key")
      allow(mock_client).to receive(:[]) do |service_name|
        expect(service_name).to eq "Account"

        if(!@mock_service)
          @mock_service = SoftLayer::Service.new("SoftLayer_Account", :client => mock_client)
          allow(@mock_service).to receive(:getObject).and_return(fixture_account_data)

          expect(@mock_service).to receive(:getHardware).and_return(fixture_bare_metal_data)
          expect(@mock_service).to receive(:getVirtualGuests).and_return(fixture_virtual_server_data)
          allow(@mock_service).to receive(:object_mask).and_return(@mock_service)

          # if we've stubbed everything out correctly... we shouldn't actually be calling the API
          expect(@mock_service).to_not receive(:call_softlayer_api_with_params)
        end

        @mock_service
      end

      test_account = SoftLayer::Account.account_for_client(mock_client)

      expect(test_account).to respond_to(:servers)
      expect(test_account).to_not respond_to(:servers=)

      servers = test_account.servers
      expect(servers.length).to eq(6)
    end
  end

  describe "fetching tickets" do
    before do
      fixture_account_data = fixture_from_json("test_account")
      fixture_open_tickets = fixture_from_json("test_tickets")
      fixture_closed_tickets = fixture_from_json("test_tickets.json")

      @mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "fake_api_key")
      allow(@mock_client).to receive(:[]) do |service_name|
        expect(service_name).to eq "Account"

        if !@mock_service

          @mock_service = SoftLayer::Service.new("SoftLayer_Account", :client => @mock_client)
          allow(@mock_service).to receive(:getObject).and_return(fixture_account_data)
          allow(@mock_service).to receive(:object_mask).and_return(@mock_service)
          allow(@mock_service).to receive(:call_softlayer_api_with_params)

          expect(@mock_service).to receive(:getOpenTickets).and_return(fixture_open_tickets)
          expect(@mock_service).to receive(:getTicketsClosedInTheLastThreeDays).and_return(fixture_closed_tickets)

          # if we've stubbed everything out correctly... we shouldn't actually be calling the API
          expect(@mock_service).to_not receive(:call_softlayer_api_with_params)
        end

        @mock_service
      end
    end

    it "responds to a tickets request" do
      test_account = SoftLayer::Account.account_for_client(@mock_client)
      expect(test_account).to respond_to(:tickets)
      expect(test_account).to_not respond_to(:tickets=)

      tickets = test_account.tickets
    end
  end

  describe "Account.account_for_client" do
    it "raises an error if there is no client available" do
      SoftLayer::Client.default_client = nil
      expect {SoftLayer::Account.account_for_client}.to raise_error
    end

    it "uses the default client if one is available" do
      mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "fake_api_key")
      allow(mock_client).to receive(:[]) do |service_name|
        mock_service = Object.new()
        allow(mock_service).to receive(:getObject).and_return({"id" => 12345})
        mock_service
      end

      SoftLayer::Client.default_client = mock_client
      mock_account = SoftLayer::Account.account_for_client
      expect(mock_account).to be_instance_of(SoftLayer::Account)
      expect(mock_account.id).to be(12345)
    end
  end

end