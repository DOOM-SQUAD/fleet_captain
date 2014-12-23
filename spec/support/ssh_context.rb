shared_context 'ssh connection established' do
  let(:fleet_client) {
    FleetCaptain::FleetClient.new('ec2-54-146-31-143.compute-1.amazonaws.com')
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
end
