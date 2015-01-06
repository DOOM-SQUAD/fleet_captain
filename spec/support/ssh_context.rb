shared_context 'ssh connection established' do
  let(:fleet_client) {
    FleetCaptain::FleetClient.new('ec2-54-146-31-143.compute-1.amazonaws.com')
  }

  before do
    # pretend the SSH tunnel is setup
    #
    # NOTE:  If you rerecord the cassettes you will need to ACTUALLY
    # establish an SSH tunnel.
    #

    if subject.respond_to? :fleet_client=
      subject.fleet_client = fleet_client
    end
    
    allow(fleet_client).to receive(:connect) do |host|
      fleet_client.instance_variable_set('@connected', true)
      fleet_client
    end
  end
end
