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
require 'rspec/autorun'

describe String, "#to_sl_object_mask" do
  it "should echo back a string with no base" do
    "blah".to_sl_object_mask.should eql("blah")
  end

  it "should prepend the base with a dot if given" do
    "blah".to_sl_object_mask("foo").should eql("foo.blah")
  end

  it "should return the empty string if given the empty string with no base" do
    "".to_sl_object_mask.should eql("")
  end

  it "should return the base with no dot if applied to the empty string" do
    "".to_sl_object_mask("foo").should eql("foo")
  end
end

describe Array,"#to_sl_object_mask" do
  it "should return and empty string if run on an empty array" do
    [].to_sl_object_mask.should eql("")
  end

  it "should call to_sl_object_mask passing the base to all its elements" do
    proxy = "Hello"
    proxy.should_receive(:to_sl_object_mask).with("")
    [proxy].to_sl_object_mask

    proxy = "Hello"
    proxy.should_receive(:to_sl_object_mask).with("foo")
    [proxy].to_sl_object_mask('foo')
  end

  it "should flatten any arrays inside of itself" do
    ["foo", ["bar", "baz"]].to_sl_object_mask("buz").should eql(["buz.foo", "buz.bar", "buz.baz"])
  end
end

describe Hash, "#to_sl_object_mask" do
  it "should return an empty string if run on an empty hash" do
	  {}.to_sl_object_mask.should eql("")
  end

  it "should call to_sl_object_mask on values with the key as the base" do
    proxy = "value"
    proxy.should_receive(:to_sl_object_mask).with("key").and_return("key.value")
    mask_elements = {"key" => proxy}.to_sl_object_mask
    mask_elements.should eql(["key.value"])
  end

  it "should resolve the mapped values with the base provided" do
    {"top" => [ "middle1", {"middle2" => "end"}]}.to_sl_object_mask.should eql(["top.middle1", "top.middle2.end"])
  end

  it "should handle a complex hash object mask with an inner empty hash" do
    { "ipAddress" => { "ipAddress" => {}}}.to_sl_object_mask.should eql(["ipAddress.ipAddress"])
  end

end