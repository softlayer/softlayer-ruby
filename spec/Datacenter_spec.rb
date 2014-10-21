#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), '../lib'))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

describe SoftLayer::Datacenter do
  let (:mock_client) do
    mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "DEADBEEFBADF00D")
    allow(mock_client[:Location]).to receive(:call_softlayer_api_with_params) do |method_name, parameters, args|
      fixture_from_json('datacenter_locations.json')
    end

    mock_client
  end

  it "retrieves a list of datacenters" do
    datacenters = SoftLayer::Datacenter.datacenters(mock_client)
    names = datacenters.collect { |datacenter| datacenter.name }
    expect(names.sort).to eq ["ams01", "dal01", "dal02", "dal04", "dal05", "dal06", "dal07", "hkg02", "hou02", "lon02", "sea01", "sjc01", "sng01", "tor01", "wdc01", "wdc03"]
  end

  it "retrieves a particular datacenter by name" do
    dal05 =  SoftLayer::Datacenter.datacenter_named("dal05", mock_client)
    expect(dal05.name).to eq "dal05"
    expect(dal05.id).to be 138124
  end
end
