shared_context 'ssh connection established' do
  let(:connection) { FleetCaptain::FleetClient::Connection.new(key_file: '~/.ssh/bork-knife-ec2.pem') }
  let(:fleet_client) {
    FleetCaptain::FleetClient.new('Test-Stack').tap do |fc|
      fc.connection = connection
    end
  }

  before do
    # pretend the SSH tunnel is setup
    #
    # NOTE:  If you rerecord the cassettes you will need to ACTUALLY
    # establish an SSH tunnel TO THE cluster leader
    #

    FleetCaptain::Service.config.cluster_client = fleet_client

    if subject.respond_to? :fleet_client=
      subject.fleet_client = fleet_client
    end

    allow(fleet_client).to receive(:connected_to_actual?).and_return(true)
    allow(fleet_client).to receive(:connected?).and_return(true)
    allow(fleet_client).to receive(:connect).and_return(fleet_client)
  end
end
