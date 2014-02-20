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

$: << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

describe SoftLayer::Account do
	it "should exist" do
		SoftLayer::Account.should_not be_nil
	end
  
  it "should fail to create an account from a nil hash" do
    expect { SoftLayer::Account.new(nil) }.to raise_error(ArgumentError)
  end
  
  it "should require the initialization hash to include an 'id' or :id" do
    expect { SoftLayer::Account.new({}) }.to raise_error(ArgumentError)
    expect { SoftLayer::Account.new(:id => "232279") }.not_to raise_error()
  end
  
  it "should return its initialization id as the account_id" do
    test_account = SoftLayer::Account.new("id" => "232279", "firstName" => "kangaroo")
    test_account.account_id.should eq("232279")
    
    another_test_acct = SoftLayer::Account.new(:id => "232279", "firstName" => "kangaroo")
    test_account.account_id.should eq("232279")
  end
  
  it "should pretend to include methods from its initialization hash" do
    test_account = SoftLayer::Account.new("id" => "232279", "firstName" => "kangaroo")

    test_account.respond_to?(:firstName).should be_true

    test_account.respond_to?(:gordon_the_wonder_dog).should be_false

    # it should be able to read the value of the hash as a method call
    test_account.firstName.should eq("kangaroo")
    
    # asking for something that's not in the hash should still raise an error
    expect { test_account.snork }.to raise_error()
  end
  
  it "should allow the user to get the default account for a service" do
    test_service = double("sl service mock")
    test_service.stub("getObject").and_return("id" => "232279", "firstName" => "kangaroo")
    
    test_account = SoftLayer::Account.default_account(test_service)
    
    test_account.account_id.should eq("232279")
    test_account.id.should eq("232279")
    test_account.firstName.should eq("kangaroo")
  end
  
  it "should implement to_ary because the method is called at weird times" do
    test_account = SoftLayer::Account.new("id" => "232279", "firstName" => "kangaroo")
    
    test_account.to_ary.should be_nil
  end
end