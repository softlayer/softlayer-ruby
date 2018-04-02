#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

require 'tempfile'

describe SoftLayer::Config do

  before :each do
    ENV.delete("SL_USERNAME")
    ENV.delete("SL_API_KEY")
    ENV.delete("SL_API_USER_AGENT")
    ENV.delete("SL_PROFILE")
  end

	it "retrieves config information from environment variables" do
		ENV.store("SL_USERNAME", "PoohBear")
		ENV.store("SL_API_KEY", "DEADBEEFBADF00D")
                ENV.store("SL_API_USER_AGENT", "de trackerz")

		expect(SoftLayer::Config.environment_settings).to eq({ :user_agent => "de trackerz", :username => "PoohBear", :api_key => "DEADBEEFBADF00D" })
	end

it "retrieves the properties from a custom file" do
    file = Tempfile.new('properties_from_file')
    begin
      file.puts("[softlayer]")
      file.puts("username = PoohBear")
      file.puts("api_key = DEADBEEFBADF00D")
      file.puts("timeout = 40")
      file.close

      settings = SoftLayer::Config.file_settings(file.path)
    ensure
      file.close
      file.unlink
    end

    expect(settings[:username]).to eq("PoohBear")
    expect(settings[:api_key]).to eq("DEADBEEFBADF00D")
    expect(settings[:timeout]).to eq(40)
  end

  it "retrieves the properties from a custom file using a custom profile" do
    ENV.store("SL_PROFILE", "softlayer_qa")
    file = Tempfile.new('properties_from_file')
    begin
      file.puts("[softlayer_dev]")
      file.puts("username = PoohBear")
      file.puts("api_key = DEADBEEFBADF00D")
      file.puts("timeout = 40")
      file.puts("\n")
      file.puts("[softlayer_qa]")
      file.puts("username = Piglet")
      file.puts("api_key = MOOOOOOOO")
      file.puts("timeout = 60")
      file.puts("\n")
      file.puts("[softlayer_prod]")
      file.puts("username = Eeyore")
      file.puts("api_key = VEG_ALL_THE_WAY")
      file.puts("timeout = 80")
      file.close

      settings = SoftLayer::Config.file_settings(file.path)
    ensure
      file.close
      file.unlink
    end

    expect(settings[:username]).to eq("Piglet")
    expect(settings[:api_key]).to eq("MOOOOOOOO")
    expect(settings[:timeout]).to eq(60)
  end

  it "retrieves the timeout field as an integer when presented as a string" do
    file = Tempfile.new('config_test')
    begin
      file.puts("[softlayer]")
      file.puts("username = PoohBear")
      file.puts("api_key = DEADBEEFBADF00D")
      file.puts("timeout = 40")
      file.close

      settings = SoftLayer::Config.file_settings(file.path)
    ensure
      file.close
      file.unlink
    end

    expect(settings[:timeout]).to eq(40)
  end
end
