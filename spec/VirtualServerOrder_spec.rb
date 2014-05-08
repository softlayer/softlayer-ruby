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

describe SoftLayer::VirtualServerOrder do
  it "puts the cpu count an order template" do
    subject.cpus = 4
    subject.virtual_guest_template["startCpus"].should == 4
  end

  it "puts the memory capacity in the order template" do
    subject.memory = 4096
    subject.virtual_guest_template["maxMemory"].should == 4096
  end

  it "puts the hostname in the order template" do
    subject.hostname = "testhostname"
    subject.virtual_guest_template["hostname"].should == "testhostname"
  end

  it "puts the domain name in the order template" do
    subject.domain = "softlayer.com"
    subject.virtual_guest_template["domain"].should == "softlayer.com"
  end

  it "orders a server with a local disk" do
    # note, we don't want the flag to be "falsy" we want it to be the boolean constant "false"
    subject.virtual_guest_template["localDiskFlag"].should be(false)

    subject.use_local_disk = true
    subject.virtual_guest_template["localDiskFlag"].should be(true)

    subject.use_local_disk = false
    subject.virtual_guest_template["localDiskFlag"].should be(false)
  end

  it "orders a sever with hourly billing" do
    # note, we don't want the flag to be "falsy" we want it to be the boolean constant "false"
    subject.virtual_guest_template["hourlyBillingFlag"].should be(false)

    subject.hourly = true
    subject.virtual_guest_template["hourlyBillingFlag"].should be(true)

    subject.hourly = false
    subject.virtual_guest_template["hourlyBillingFlag"].should be(false)
  end

  it "orders a dedicated host" do
    subject.virtual_guest_template["dedicatedAccountHostOnlyFlag"].should be_false
    subject.dedicated_host = true
    subject.virtual_guest_template["dedicatedAccountHostOnlyFlag"].should be_true
  end

  it "orders a server without a public network " do
    subject.virtual_guest_template["privateNetworkOnlyFlag"].should be_false
    subject.private_network_only = true
    subject.virtual_guest_template["privateNetworkOnlyFlag"].should be_true
  end

  it "orders a server in a particular data center" do
    subject.virtual_guest_template["datacenter"].should be_nil
    subject.datacenter = "dal05"
    subject.virtual_guest_template["datacenter"].should == { "name" => "dal05" }
  end

  it "lets the order provide user metadata" do
    subject.virtual_guest_template["userData"].should be_nil
    subject.user_metadata = "MetadataValue"
    subject.virtual_guest_template['userData'].should == [{'value' => "MetadataValue"}]
  end

  it "allows an order to provide a max interface card speed" do
    subject.virtual_guest_template["networkComponents"].should be_nil
    subject.max_nic_speed = 1000
    subject.virtual_guest_template['networkComponents'].should == [{'maxSpeed' => 1000}]
  end

  it "provides a post-provisioning script URI" do
    subject.virtual_guest_template["postInstallScriptUri"].should be_nil
    subject.post_provision_uri = "file:///some/fancyscript.sh"
    subject.virtual_guest_template['postInstallScriptUri'].should == "file:///some/fancyscript.sh"
  end

  it "provides root user ssh keys" do
    subject.virtual_guest_template["sshKeys"].should be_nil
    subject.ssh_keys = ["one", "two", "three"]
    subject.virtual_guest_template['sshKeys'].should == [{"id"=>"one"}, {"id"=>"two"}, {"id"=>"three"}]
  end

  it "puts a disk image id into the order template" do
    subject.virtual_guest_template["blockDeviceTemplateGroup"].should be_nil
    subject.image_id = 12345
    subject.virtual_guest_template['blockDeviceTemplateGroup'].should == {"globalIdentifier" => 12345}
  end

  it "puts an OS identifier into the order template" do
    subject.virtual_guest_template["operatingSystemReferenceCode"].should be_nil
    subject.os_referenceCode = 'UBUNTU_12_64'
    subject.virtual_guest_template['operatingSystemReferenceCode'].should == 'UBUNTU_12_64'
  end

  it "allows an image id to override an os reference code when both are provide" do
    subject.virtual_guest_template["blockDeviceTemplateGroup"].should be_nil
    subject.virtual_guest_template["operatingSystemReferenceCode"].should be_nil

    subject.image_id = 12345
    subject.os_referenceCode = 'UBUNTU_12_64'

    subject.virtual_guest_template['blockDeviceTemplateGroup'].should == {"globalIdentifier" => 12345}
    subject.virtual_guest_template['operatingSystemReferenceCode'].should be_nil
  end

  it "puts the public VLAN id into an order template" do
    subject.virtual_guest_template["primaryNetworkComponent"].should be_nil
    subject.public_vlan_id = 12345
    subject.virtual_guest_template["primaryNetworkComponent"].should == { "networkVlan" => { "id" => 12345 } }
  end

  it "puts the private VLAN id into an order template" do
    subject.virtual_guest_template["primaryBackendNetworkComponent"].should be_nil
    subject.private_vlan_id = 12345
    subject.virtual_guest_template["primaryBackendNetworkComponent"].should == { "networkVlan" => { "id" => 12345 } }
  end

  it "sets up disks in the order template" do
    subject.virtual_guest_template["blockDevices"].should be_nil
    subject.disks = [2, 25, 50]
    subject.virtual_guest_template["blockDevices"].should == [
      {"device"=>"0", "diskImage"=>{"capacity"=>2}},
      {"device"=>"1", "diskImage"=>{"capacity"=>25}},
      {"device"=>"2", "diskImage"=>{"capacity"=>50}}
    ]
  end

  it "calls the softlayer API to validate an order template" do
    test_order = SoftLayer::VirtualServerOrder.new()
    test_order.cpus = 2
    test_order.memory = 2048
    test_order.hostname = "ruby-client-test"
    test_order.domain = "kitchentools.com"

    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')
    virtual_guest_order_service = client["Virtual_Guest"]
    virtual_guest_order_service.stub(:call_softlayer_api_with_params)

    expect(virtual_guest_order_service).to receive(:generateOrderTemplate).with(test_order.virtual_guest_template)
    test_order.verify(client)
  end

  it "calls the softlayer API to place an order for a new virtual server" do
    test_order = SoftLayer::VirtualServerOrder.new()
    test_order.cpus = 2
    test_order.memory = 2048
    test_order.hostname = "ruby-client-test"
    test_order.domain = "kitchentools.com"

    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')
    virtual_guest_order_service = client["Virtual_Guest"]
    virtual_guest_order_service.stub(:call_softlayer_api_with_params)

    expect(virtual_guest_order_service).to receive(:createObject).with(test_order.virtual_guest_template)
    test_order.place_order!(client)
  end
end
