#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

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

    SoftLayer::ProductPackage.packages_with_key_name('FAKE_KEY_NAME', client)
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

  describe "class methods for getting to packages" do
    let(:mock_client) do
      client = SoftLayer::Client.new(:username => "fake_user", :api_key => "BADKEY")
      product_package_service = client['Product_Package']

      allow(product_package_service).to receive(:call_softlayer_api_with_params).with(:getAllObjects, instance_of(SoftLayer::APIParameterFilter), []).and_return([fixture_from_json("Product_Package")])
      client
    end

    it "calling with a client should work fine" do
      expect { SoftLayer::ProductPackage.packages_with_key_name('BARE_METAL_CORE', mock_client) }.to_not raise_error
      expect { SoftLayer::ProductPackage.virtual_server_package(mock_client) }.to_not raise_error
      expect { SoftLayer::ProductPackage.bare_metal_instance_package(mock_client) }.to_not raise_error
      expect { SoftLayer::ProductPackage.bare_metal_server_packages(mock_client) }.to_not raise_error
    end

    it "calling with default client should work" do
      SoftLayer::Client.default_client = mock_client
      expect { SoftLayer::ProductPackage.packages_with_key_name('BARE_METAL_CORE') }.to_not raise_error
      expect { SoftLayer::ProductPackage.virtual_server_package() }.to_not raise_error
      expect { SoftLayer::ProductPackage.bare_metal_instance_package() }.to_not raise_error
      expect { SoftLayer::ProductPackage.bare_metal_server_packages() }.to_not raise_error
      SoftLayer::Client.default_client = nil
    end

    it "calling with no client should raise" do
      SoftLayer::Client.default_client = nil
      expect { SoftLayer::ProductPackage.packages_with_key_name('BARE_METAL_CORE') }.to raise_error
      expect { SoftLayer::ProductPackage.virtual_server_package() }.to raise_error
      expect { SoftLayer::ProductPackage.bare_metal_instance_package() }.to raise_error
      expect { SoftLayer::ProductPackage.bare_metal_server_packages() }.to raise_error
    end
  end
end