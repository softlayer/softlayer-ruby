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


describe SoftLayer::ModelBase do
  describe "#initialize" do
    it "rejects hashes without an id" do
      expect { SoftLayer::ModelBase.new(nil, {}) }.to raise_error(ArgumentError)
      expect { SoftLayer::ModelBase.new(nil, {"id" => "someID"}) }.not_to raise_error
    end

    it "rejects nil hashes" do
      expect { SoftLayer::ModelBase.new(nil, nil) }.to raise_error(ArgumentError)
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
    test_model = SoftLayer::ModelBase.new(nil, { "id" => "12345" })
    expect(test_model).to respond_to(:to_ary)
    expect(test_model.to_ary).to be_nil
  end

  it "realizes when low-level hash keys are added" do
    test_model = SoftLayer::ModelBase.new(nil, { "id" => "12345" })
    allow(test_model).to receive(:softlayer_properties) { { "id" => "12345", "newInfo" => "fun" } }
    expect(test_model.has_sl_property? :newInfo).to be_false
    test_model.refresh_details()
    expect(test_model.has_sl_property? :newInfo).to be_true
  end

  it "realizes when low-level hash keys are removed" do
    test_model = SoftLayer::ModelBase.new(nil, { "id" => "12345", "newInfo" => "fun" })
    allow(test_model).to receive(:softlayer_properties) { { "id" => "12345" } }
    expect(test_model.has_sl_property? :newInfo).to be_true
    test_model.refresh_details()
    expect(test_model.has_sl_property? :newInfo).to be_false
  end
end