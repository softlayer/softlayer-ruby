#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

describe SoftLayer::Firewall do
  it "should have a class representing a firewall" do
    expect{ SoftLayer::Firewall.new("not really a client", { "id" => 12345 }) }.to_not raise_error
  end
end