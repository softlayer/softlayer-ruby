#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

describe SoftLayer::ModelBase do
  describe "#initialize" do
    it "rejects hashes without an id" do
      mock_client = double("Mock SoftLayer Client")
      expect { SoftLayer::ModelBase.new(mock_client, {}) }.to raise_error(ArgumentError)
      expect { SoftLayer::ModelBase.new(mock_client, {"id" => "someID"}) }.not_to raise_error
    end

    it "rejects models created with no client" do
      expect { SoftLayer::ModelBase.new(nil, nil) }.to raise_error(ArgumentError)
    end

    it "rejects nil hashes" do
      mock_client = double("Mock SoftLayer Client")
      expect { SoftLayer::ModelBase.new(mock_client, nil) }.to raise_error(ArgumentError)
    end

    it "remembers its first argument as the client" do
      mock_client = double("Mock SoftLayer Client")
      test_model = SoftLayer::ModelBase.new(mock_client, { "id" => "12345"});
      expect(test_model.softlayer_client).to be(mock_client)
    end
  end

  it "allows access to raw softlayer properties" do
    mock_client = double("Mock SoftLayer Client")
    test_model = SoftLayer::ModelBase.new(mock_client, { "id" => "12345"});
    expect(test_model[:id]).to eq("12345")
    expect(test_model["id"]).to eq("12345")
  end

  it "allows access to exposed softlayer properties" do
    mock_client = double("Mock SoftLayer Client")
    test_model = SoftLayer::ModelBase.new(mock_client, { "id" => "12345"});
    expect(test_model.id).to eq("12345")
  end

  it "returns nil from to_ary" do
    mock_client = double("Mock SoftLayer Client")
    test_model = SoftLayer::ModelBase.new(mock_client, { "id" => "12345" })
    expect(test_model).to respond_to(:to_ary)
    expect(test_model.to_ary).to be_nil
  end

  it "realizes when low-level hash keys are added" do
    mock_client = double("Mock SoftLayer Client")
    test_model = SoftLayer::ModelBase.new(mock_client, { "id" => "12345" })
    allow(test_model).to receive(:softlayer_properties) { { "id" => "12345", "newInfo" => "fun" } }
    expect(test_model.has_sl_property? :newInfo).to be(false)
    test_model.refresh_details()
    expect(test_model.has_sl_property? :newInfo).to be(true)
  end

  it "realizes when low-level hash keys are removed" do
    mock_client = double("Mock SoftLayer Client")
    test_model = SoftLayer::ModelBase.new(mock_client, { "id" => "12345", "newInfo" => "fun" })
    allow(test_model).to receive(:softlayer_properties) { { "id" => "12345" } }
    expect(test_model.has_sl_property? :newInfo).to be(true)
    test_model.refresh_details()
    expect(test_model.has_sl_property? :newInfo).to be(false)
  end
end