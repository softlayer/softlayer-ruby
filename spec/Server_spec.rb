#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++



$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

describe SoftLayer::Server do
	it "is an abstract base class" do
		mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "DEADBEEFBADF00D")
		allow(mock_client).to receive(:[]) do |service_name|
			service = mock_client.service_named(service_name)
			allow(service).to receive(:call_softlayer_api_with_params)
			service
		end

		expect { SoftLayer::Server.new(mock_client, { "id" => 12345 }) }.to raise_error
	end
end