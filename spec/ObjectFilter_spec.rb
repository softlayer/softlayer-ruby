#
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), '../lib'))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

describe SoftLayer::ObjectFilter do
  it "is empty hash when created" do
    test_filter = SoftLayer::ObjectFilter.new()
    expect(test_filter).to eq({})
  end

  it "adds empty object filter sub-elements for unknown keys" do
    test_filter = SoftLayer::ObjectFilter.new()
    value = test_filter["foo"]

    expect(value).to_not be_nil
    expect(value).to eq({})
    expect(value).to be_kind_of(SoftLayer::ObjectFilter)
  end

  describe ":build" do
    it "builds object filters from a key path and query string" do
      object_filter = SoftLayer::ObjectFilter.build("hardware.domain", '*riak*');
      expect(object_filter).to eq({
        "hardware" => {
          "domain" => {
            'operation' => '*= riak'
          }}})
    end

    it "builds object filters from a key path and a hash" do
      object_filter = SoftLayer::ObjectFilter.build("hardware.domain", {'bogus' => 'but fun'});
      expect(object_filter).to eq({
        "hardware" => {
          "domain" => {
            'bogus' => 'but fun'
          }}})
    end

    it "builds object filters from a key path and am ObjectFilterOperation" do
      filter_operation = SoftLayer::ObjectFilterOperation.new('~', 'wwdc')
      object_filter = SoftLayer::ObjectFilter.build("hardware.domain", filter_operation);
      expect(object_filter).to eq ({
        "hardware" => {
          "domain" => {
            'operation' => '~ wwdc'
            }}})
    end

    it "builds object filters from a key path and block" do
      object_filter = SoftLayer::ObjectFilter.build("hardware.domain") { contains 'riak' };
      expect(object_filter).to eq ({
        "hardware" => {
          "domain" => {
            'operation' => '*= riak'
          }
        }
      })
    end
  end

  describe ":query_to_filter_operation" do
    it "translates sample strings into valid operation structures" do
      expect(SoftLayer::ObjectFilter.query_to_filter_operation('3')).to eq({'operation' => 3 })
      expect(SoftLayer::ObjectFilter.query_to_filter_operation('value')).to eq({'operation' => "_= value" })
      expect(SoftLayer::ObjectFilter.query_to_filter_operation('value*')).to eq({'operation' => "^= value" })
      expect(SoftLayer::ObjectFilter.query_to_filter_operation('*value')).to eq({'operation' => "$= value" })
      expect(SoftLayer::ObjectFilter.query_to_filter_operation('*value*')).to eq({'operation' => "*= value" })
      expect(SoftLayer::ObjectFilter.query_to_filter_operation('~ value')).to eq({'operation' => "~ value" })
      expect(SoftLayer::ObjectFilter.query_to_filter_operation('> value')).to eq({'operation' => "> value" })
      expect(SoftLayer::ObjectFilter.query_to_filter_operation('< value')).to eq({'operation' => "< value" })
      expect(SoftLayer::ObjectFilter.query_to_filter_operation('>= value')).to eq({'operation' => ">= value" })
      expect(SoftLayer::ObjectFilter.query_to_filter_operation('<= value')).to eq({'operation' => "<= value" })
      expect(SoftLayer::ObjectFilter.query_to_filter_operation('*= value')).to eq({'operation' => "*= value" })
      expect(SoftLayer::ObjectFilter.query_to_filter_operation('^= value')).to eq({'operation' => "^= value" })
      expect(SoftLayer::ObjectFilter.query_to_filter_operation('$= value')).to eq({'operation' => "$= value" })
      expect(SoftLayer::ObjectFilter.query_to_filter_operation('_= value')).to eq({'operation' => "_= value" })
      expect(SoftLayer::ObjectFilter.query_to_filter_operation('!~ value')).to eq({'operation' => "!~ value" })
    end
  end

  describe ":build operations translate to correct operators" do
    it "handles the common operators" do
      object_filter = SoftLayer::ObjectFilter.build("domain") { contains 'value  ' }
      expect(object_filter).to eq({ "domain" => { 'operation' => "*= value"} })

      object_filter = SoftLayer::ObjectFilter.build("domain") { begins_with '  value' }
      expect(object_filter).to eq({ "domain" => { 'operation' => "^= value"} })

      object_filter = SoftLayer::ObjectFilter.build("domain") { ends_with ' value' }
      expect(object_filter).to eq({ "domain" => { 'operation' => "$= value"} })

      object_filter = SoftLayer::ObjectFilter.build("domain") { is 'value ' }
      expect(object_filter).to eq({ "domain" => { 'operation' => "_= value"} })

      object_filter = SoftLayer::ObjectFilter.build("domain") { is_not ' value' }
      expect(object_filter).to eq({ "domain" => { 'operation' => "!= value"} })

      object_filter = SoftLayer::ObjectFilter.build("domain") { is_greater_than 'value ' }
      expect(object_filter).to eq({ "domain" => { 'operation' => "> value"} })

      object_filter = SoftLayer::ObjectFilter.build("domain") { is_less_than ' value' }
      expect(object_filter).to eq({ "domain" => { 'operation' => "< value"} })

      object_filter = SoftLayer::ObjectFilter.build("domain") { is_greater_or_equal_to ' value' }
      expect(object_filter).to eq({ "domain" => { 'operation' => ">= value"} })

      object_filter = SoftLayer::ObjectFilter.build("domain") { is_less_or_equal_to 'value ' }
      expect(object_filter).to eq({ "domain" => { 'operation' => "<= value"} })

      object_filter = SoftLayer::ObjectFilter.build("domain") { contains_exactly ' value' }
      expect(object_filter).to eq({ "domain" => { 'operation' => "~ value"} })

      object_filter = SoftLayer::ObjectFilter.build("domain") { does_not_contain ' value' }
      expect(object_filter).to eq({ "domain" => { 'operation' => "!~ value"} })
    end
  end
end
