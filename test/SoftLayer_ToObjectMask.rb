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
  it "should echo back a string" do
    "blah".to_sl_object_mask.should eql("blah")
  end

  it "should return the empty string if given the empty string" do
    "".to_sl_object_mask.should eql("")
  end
end

describe Array,"#to_sl_object_mask" do
  it "should return and empty string if run on an empty array" do
    [].to_sl_object_mask.should eql("")
  end

  it "should handle simple arrays" do
    ["foo", "bar", "baz"].to_sl_object_mask().should eql("foo,bar,baz")
  end
  
  it "should flatten any arrays inside of itself" do
    ["foo", ["bar", "baz"]].to_sl_object_mask().should eql("foo,bar,baz")
  end
end

describe Hash, "#to_sl_object_mask" do
  it "should return an empty string if run on an empty hash" do
      {}.to_sl_object_mask.should eql("")
  end
  
  it "should return a dot expression for a simple string value" do
    {"foo" => "foobar"}.to_sl_object_mask.should eql("foo.foobar")
  end
  
  it "should return a bracket expression for an array value" do
    {"foo" => ["one", "two", "three"]}.to_sl_object_mask.should eql("foo[one,two,three]")
  end
  
  it "should handle nested hashes" do
    {"foo" => {"sub" => "resub"}}.to_sl_object_mask.should eql("foo[sub.resub]")
  end

  it "should resolve the mapped values" do
    {"top" => [ "middle1", {"middle2" => "end"}]}.to_sl_object_mask.should eql("top[middle1,middle2.end]")
  end
  
  it "should handle a complex hash object mask with an inner empty hash" do
    { "ipAddress" => { "ipAddress" => {}}}.to_sl_object_mask.should eql("ipAddress[ipAddress]")
  end  
end

describe SoftLayer::ObjectMaskProperty, "#initialize" do
  it "should initialize with a name" do
    mask_property = SoftLayer::ObjectMaskProperty.new("simple_name")
    mask_property.name.should eql("simple_name")
  end

  it "should raise argument error if given an nil name" do
    expect { SoftLayer::ObjectMaskProperty.new(nil) }.to raise_error(ArgumentError)
  end
  
  it "should raise argument error if given an empty name" do
    expect { SoftLayer::ObjectMaskProperty.new("") }.to raise_error(ArgumentError)
  end
end

describe SoftLayer::ObjectMaskProperty, "#to_sl_object_mask" do
  it "should convert simple mask properties to string" do
    mask_property = SoftLayer::ObjectMaskProperty.new("simple_name")
    mask_property.to_sl_object_mask.should eql("simple_name")
  end

  it "should convert mask properties with a type" do
    mask_property = SoftLayer::ObjectMaskProperty.new("simple_name")
    mask_property.type = "property_type"
    mask_property.to_sl_object_mask.should eql("simple_name(property_type)")
  end
  
  it "should convert mask properties with simple subproperties" do
    mask_property = SoftLayer::ObjectMaskProperty.new("simple_name")
    mask_property.type = "property_type"
    mask_property.subproperties = "subproperty"
    mask_property.to_sl_object_mask.should eql("simple_name(property_type).subproperty")
  end
  
  it "should allow Array subproperties" do
    mask_property = SoftLayer::ObjectMaskProperty.new("simple_name")
    mask_property.subproperties = ["one", "two", "three"]
    mask_property.to_sl_object_mask.should eql("simple_name[one,two,three]")
  end
  
  it "should allow Hash subproperties" do
    mask_property = SoftLayer::ObjectMaskProperty.new("simple_name")
    mask_property.subproperties = { "foo" => "subfoo" }
    mask_property.to_sl_object_mask.should eql("simple_name[foo.subfoo]")
  end
end
