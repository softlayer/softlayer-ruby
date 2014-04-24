shared_examples_for "server with mutable hostname" do
	it "has a method to change the host name" do
		server.should respond_to(:set_hostname!)
	end
  
  it "rejects nil hostnames" do
    expect { server.set_hostname!(nil) }.to  raise_error(ArgumentError)
  end

  it "rejects empty hostnames" do
    expect { server.set_hostname!("") }.to raise_error(ArgumentError)
  end
end

shared_examples_for "server with port speed" do
	it "has a method to change port speed" do
		server.should respond_to(:change_port_speed)
	end

	it "changes public port speed if no interface is specified" do
		server.service.should receive(:setPublicNetworkInterfaceSpeed).with(10)
		server.change_port_speed(10)
	end

	it "changes public port speed if told to do so" do
		server.service.should receive(:setPublicNetworkInterfaceSpeed).with(10)
		server.change_port_speed(10, true)
	end

	it "changes private port speed if told to change private" do
		server.service.should receive(:setPrivateNetworkInterfaceSpeed).with(10)
		server.change_port_speed(10, false)
	end
end