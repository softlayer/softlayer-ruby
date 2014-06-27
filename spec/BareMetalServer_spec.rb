#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++



$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

require 'shared_server'

describe SoftLayer::BareMetalServer do
	let (:sample_server) do
		mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "DEADBEEFBADF00D")
		allow(mock_client).to receive(:[]) do |service_name|
			service = mock_client.service_named(service_name)
			allow(service).to receive(:call_softlayer_api_with_params)
			service
		end

		SoftLayer::BareMetalServer.new(mock_client, { "id" => 12345 })
	end

  it "identifies itself with the SoftLayer_Hardware service" do
    service = sample_server.service
    expect(service.server_object_id).to eq(12345)
    expect(service.target.service_name).to eq "SoftLayer_Hardware"
  end

	it_behaves_like "server with port speed" do
		let (:server) { sample_server }
	end

	it "can be cancelled" do
		mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "DEADBEEFBADF00D")
		allow(mock_client).to receive(:[]) do |service_name|
			expect(service_name).to eq "Ticket"

			service = mock_client.service_named(service_name)
			expect(service).to receive(:createCancelServerTicket).with(12345, 'Migrating to larger server', 'moving on up!', true, 'HARDWARE')
			allow(service).to receive(:call_softlayer_api_with_params)
			service
		end

		fake_server = SoftLayer::BareMetalServer.new(mock_client, { "id" => 12345 })
		fake_server.cancel!(:migrate_larger, 'moving on up!' )
	end
end