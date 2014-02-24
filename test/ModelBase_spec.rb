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
  it "should reject hashes without id" do
    expect { SoftLayer::ModelBase.new(nil, {}) }.to raise_error(ArgumentError)
    expect { SoftLayer::ModelBase.new(nil, {:id => "someID"}) }.not_to raise_error
  end
  
  it "should reject nil hashes" do
    expect { SoftLayer::ModelBase.new(nil, nil) }.to raise_error(ArgumentError)
  end
  
  it "return values from its hash as methods" do
    test_model = SoftLayer::ModelBase.new(nil, { :id => nil, :kangaroo => "Fun"});
    test_model.kangaroo.should == "Fun"
  end
  
  it "should return nil from to_ary" do
    test_model = SoftLayer::ModelBase.new(nil, { :id => "" })
    test_model.should respond_to(:to_ary)
    test_model.to_ary.should be_nil
  end
end