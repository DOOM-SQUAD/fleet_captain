require 'spec_helper'
require 'capistrano/fleet_captain'

describe Capistrano::FleetCaptain do

  # mimic capistranos rake context setup
  def fetch(key)
    { 
      fleet_endpoint: 'http://127.0.0.1:4001'
    }[key]
  end

  let(:cap_object) { Capistrano::FleetCaptain.new(self, Capistrano::FleetCaptain::DefaultStrategy) }
  subject { cap_object }

  before do
    FleetCaptain.fleetfile(File.expand_path(File.join(__dir__, '../fixtures/Fleetfile')))
  end

  after { FleetCaptain.services.clear }

  describe '#docker', :vcr do
    it 'should be a fleetcaptain client' do
      expect(subject.docker_client).to be_a ::FleetCaptain::DockerClient
    end
  end

  describe '#fleet_client', :vcr do
    subject { cap_object.fleet_client }
    it { is_expected.to be_a FleetCaptain::FleetClient }
  end

  describe '#cluster' do
    subject { cap_object.cluster(:list) }

    it "passes the fleet operation to the client" do
      expect(cap_object.fleet_client).to receive(:list)
      subject
    end
  end

  describe '#new_locally', :vcr do
    include_context 'ssh connection established'

    before do
      subject.fleet_client = fleet_client
    end

    it 'should include units in the fleet file not on the cluster' do
      expect(subject.new_locally).to include FleetCaptain::Service['hello_world']
    end
  end

  describe '#identical_services', :vcr do
    include_context 'ssh connection established'
    
    let(:truebox) { FleetCaptain::Service['truebox'] }

    it 'returns services present in both fleetfile and cluster' do
      expect(subject.identical_services.to_a).to eq [truebox]
    end
  end

  describe '#changed_locally', :vcr do
    include_context 'ssh connection established'

    let(:truebox) { FleetCaptain::Service['truebox'] }

    it 'should list changed units' do
      expect { truebox.start = [run: '/bin/bash false'] }
        .to change { subject.changed_locally.to_a }
        .from([])
        .to([truebox])
    end
  end

  describe '#removed_locally', :vcr do
    include_context 'ssh connection established'

    let(:removed_unit) { <<-UNIT.strip_heredoc
       [Unit]
       Description=Hello World
       Name=Unnamed
       
       [Service]
       ExecStart=/bin/bash -c "while true; do echo \\"Hello, world\\"; sleep 1; done"
    UNIT
    } 

    it 'shows locally removed units' do
      expect(subject.removed_locally.to_a.first.to_unit).to eq removed_unit
    end
  end

  describe '#register', :vcr do
    include_context 'ssh connection established'
    include_context 'units'

    it 'uploads the systemd unit file to the cluster' do
      expect(subject.register(falsebox)).to eq true
    end
  end

  describe '#start', :vcr do
    include_context 'ssh connection established'
    include_context 'units'

    context 'starting a registered box' do
      before do
        subject.register(runbox)
        loop until subject.loaded?(runbox)
      end

      it 'starts the runbox file on the cluster' do
        expect(subject.start(runbox)).to eq true
      end
    end

    context 'starting an unregistered serviced', :vcr do
      it 'do not do that' do
        expect { subject.start(runbox) }
          .to raise_error FleetCaptain::ServiceNotRegistered
      end
    end
  end


  describe '#stop' do
    #include_context 'ssh connection established'
    #include_context 'runbox'

    #it 'stops the service on the cluster' do
    #  subject.start(runbox)
    #  expect(subject.stop(runbox)).to eq true
    #end
  end
  
  describe '#remove'
  describe '#restart'

  describe '#local_services' do
    subject { cap_object.local_services }
    it "contains only FleetCaptain::Service objects" do
      subject.each do |service|
        expect(service).to be_instance_of FleetCaptain::Service
      end
    end

    it 'contains objects defined only in the Fleetfile' do
      expect(subject.length).to eq 2
    end
  end
end
