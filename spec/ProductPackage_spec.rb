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

describe SoftLayer::ProductPackage do
  it "requests packages by key name" do
    client = SoftLayer::Client.new(:username => "fake_user", :api_key => "BADKEY")
    product_package_service = client['Product_Package']

    expect(product_package_service).to receive(:call_softlayer_api_with_params) do |method_name, parameters, args|
      expect(method_name).to be(:getAllObjects)
      expect(parameters.server_object_filter).to_not be_nil
      expect(args).to be_empty

      []
    end

    SoftLayer::ProductPackage.packages_with_key_name(client, 'FAKE_KEY_NAME')
  end
  
  it "identifies itself with the Product_Package service" do
    mock_client = SoftLayer::Client.new(:username => "fake_user", :api_key => "BADKEY")
    allow(mock_client).to receive(:[]) do |service_name|
      expect(service_name).to eq "Product_Package"
      mock_service = SoftLayer::Service.new("SoftLayer_Product_Package", :client => mock_client)

      # mock out call_softlayer_api_with_params so the service doesn't actually try to
      # communicate with the api endpoint
      allow(mock_service).to receive(:call_softlayer_api_with_params)
      
      mock_service
    end

    fake_package = SoftLayer::ProductPackage.new(mock_client, {"id" => 12345})
    expect(fake_package.service.server_object_id).to eq(12345)
    expect(fake_package.service.target.service_name).to eq "SoftLayer_Product_Package"
  end
end