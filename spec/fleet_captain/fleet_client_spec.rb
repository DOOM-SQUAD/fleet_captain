require 'spec_helper'

FleetCaptain::AwsClient.config do |c|
  c.access_key_id = 'AKIAIQPPJCPWBSL24U3A'
  c.secret_access_key = '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'
  c.region = 'us-east-1'
end


describe FleetCaptain::FleetClient do
  include_context 'ssh connection established'

  let(:expected_unit) {
    FleetCaptain::Service.from_unit(<<-UNIT.strip_heredoc)
    [Unit]
    Description=Hello World
    
    [Service]
    ExecStart=/bin/bash -c "while true; do echo \\\"Hello, world\\\"; sleep 1; done"
    UNIT
  }

  it 'connects to the fleet actual via ssh tunnel', :vcr do
    expect(fleet_client.list.first).to eq expected_unit
  end

  it 'raises a connection error if the ssh tunnel cannot be established' do
    allow(fleet_client).to receive(:establish_ssh_tunnel!) do
      raise 'fatal'
    end

    expect { fleet_client.list }.to raise_error FleetCaptain::FleetClient::ConnectionError
  end

  describe 'connecting to the fleet', :live do
    it 'can retrieve a list of machines' do
      expect(fleet_client.machines.length).to be 3
    end
  end

  describe 'actual', :live do
    before do
      FleetCaptain::AwsClient.configure do |c|
        c.access_key_id = 'AKIAIQPPJCPWBSL24U3A'
        c.secret_access_key = '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'
        c.region = 'us-east-1'
      end
    end

    let(:fleet_client) {
      FleetCaptain::FleetClient.new('Test-Stack', key_file: '~/.ssh/bork-knife-ec2.pem')
    }

    it 'dynamically determines the etcd cluster leader' do
      expect(fleet_client.actual).to eq 'ec2-54-87-71-129.compute-1.amazonaws.com'
    end
  end
end
