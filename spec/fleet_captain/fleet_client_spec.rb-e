require 'spec_helper'

describe FleetCaptain::FleetClient do
  let(:expected) {
    {"action"=>"get", 
     "node"=>{"key"=>"/_coreos.com/fleet/unit", 
              "dir"=>true, 
              "nodes"=>[
                {"key"=>"/_coreos.com/fleet/unit/e55c0aeb44ba0b68004ceb8a200e685194448b45",
                 "value"=>"{\"Raw\":\"[Unit]\\nDescription=Hello World\\n\\n[Service]\\nExecStart=/bin/bash -c \\\"while true; do echo \\\\\\\"Hello, world\\\\\\\"; sleep 1; done\\\"\\n\"}",
                 "modifiedIndex"=>633, 
                 "createdIndex"=>633}], 
              "modifiedIndex"=>633, 
              "createdIndex"=>633}}
  }

  let(:fleet_client) {
    FleetCaptain::FleetClient.new('www.app.com', 'http://127.0.0.1:4001')
  }

  before do
    # pretend the SSH tunnel is setup
    #
    # NOTE:  If you rerecord the cassettes you will need to ACTUALLY
    # establish an SSH tunnel.
    
    allow(fleet_client).to receive(:queue).and_return([])
    allow(fleet_client).to receive(:establish_ssh_tunnel!) do
      fleet_client.queue << :ready
    end
  end

  it 'connects to the fleet actual via ssh tunnel', :vcr do
    expect(fleet_client.list).to eq expected
  end

  it 'raises a connection error if the ssh tunnel cannot be established' do
    allow(fleet_client).to receive(:establish_ssh_tunnel!) do
      raise 'fatal'
    end

    expect { fleet_client.list }.to raise_error FleetCaptain::FleetClient::ConnectionError
  end
end
