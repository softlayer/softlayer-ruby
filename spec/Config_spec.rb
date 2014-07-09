#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

describe SoftLayer::Config do
	it "retrieves config information from environment variables" do
		ENV.store("SL_USERNAME", "PoohBear")
		ENV.store("SL_API_KEY", "DEADBEEFBADF00D")

		expect(SoftLayer::Config.environment_settings).to eq({ :username => "PoohBear", :api_key => "DEADBEEFBADF00D" })
	end
end
