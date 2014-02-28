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
    test_filter.should eq({})
  end
  
  it "adds empty object filter sub-elements for unknown keys" do
    test_filter = SoftLayer::ObjectFilter.new()
    value = test_filter["foo"]
    
    value.should_not be_nil
    value.should eq({})
    value.should be_kind_of(SoftLayer::ObjectFilter)
  end
  
  describe ":build" do
    it "builds object filters from a key path and query string" do
      object_filter = SoftLayer::ObjectFilter.build("hardware.domain", '*riak*');
      object_filter.should == { 
        "hardware" => {
          "domain" => {
            'operation' => '*= riak'
          }}}
    end
    
    it "builds object filters from a key path and a hash" do
      object_filter = SoftLayer::ObjectFilter.build("hardware.domain", {'bogus' => 'but fun'});
      object_filter.should == { 
        "hardware" => {
          "domain" => {
            'bogus' => 'but fun'
          }}}
    end
    
    it "builds object filters from a key path and am ObjectFilterOperation" do
      filter_operation = SoftLayer::ObjectFilterOperation.new('~', 'wwdc')
      object_filter = SoftLayer::ObjectFilter.build("hardware.domain", filter_operation);
      object_filter.should == { 
        "hardware" => {
          "domain" => {
            'operation' => '~ wwdc'
            }}}
    end
  
    it "builds object filters from a key path and block" do
      object_filter = SoftLayer::ObjectFilter.build("hardware.domain") { contains 'riak' };
      object_filter.should == { 
        "hardware" => {
          "domain" => {
            'operation' => '*= riak'
          }
        }
      }
    end
  end  
  
  describe ":query_to_filter_operation" do  
    it "translates sample strings into valid operation structures" do
      SoftLayer::ObjectFilter.query_to_filter_operation('value').should == {'operation' => "_= value" }
      SoftLayer::ObjectFilter.query_to_filter_operation('value*').should == {'operation' => "^= value" }
      SoftLayer::ObjectFilter.query_to_filter_operation('*value').should == {'operation' => "$= value" }
      SoftLayer::ObjectFilter.query_to_filter_operation('*value*').should == {'operation' => "*= value" }
      SoftLayer::ObjectFilter.query_to_filter_operation('~ value').should == {'operation' => "~ value" }
      SoftLayer::ObjectFilter.query_to_filter_operation('> value').should == {'operation' => "> value" }
      SoftLayer::ObjectFilter.query_to_filter_operation('< value').should == {'operation' => "< value" }
      SoftLayer::ObjectFilter.query_to_filter_operation('>= value').should == {'operation' => ">= value" }
      SoftLayer::ObjectFilter.query_to_filter_operation('<= value').should == {'operation' => "<= value" }
      SoftLayer::ObjectFilter.query_to_filter_operation('*= value').should == {'operation' => "*= value" }
      SoftLayer::ObjectFilter.query_to_filter_operation('^= value').should == {'operation' => "^= value" }
      SoftLayer::ObjectFilter.query_to_filter_operation('$= value').should == {'operation' => "$= value" }
      SoftLayer::ObjectFilter.query_to_filter_operation('_= value').should == {'operation' => "_= value" }
      SoftLayer::ObjectFilter.query_to_filter_operation('!~ value').should == {'operation' => "!~ value" }
    end
  end
end