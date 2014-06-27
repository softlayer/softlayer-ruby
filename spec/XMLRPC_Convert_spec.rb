#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++



$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'

describe XMLRPC::Convert,"::fault" do
  it "converts faults with faultCodes that are strings to FaultException objects" do
    fault_hash = { "faultCode" => "The SLAPI returns strings where it shouldn't", "faultString" => "This is the actual fault"}

    expect { XMLRPC::Convert.fault(fault_hash) }.not_to raise_error
    exception = XMLRPC::Convert.fault(fault_hash)
    expect(exception).to be_kind_of(XMLRPC::FaultException)
    expect(exception.faultCode).to eq(fault_hash["faultCode"])
    expect(exception.faultString).to eq(fault_hash["faultString"])
  end
end
