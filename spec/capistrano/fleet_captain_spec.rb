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

  describe '#fleet' do
    subject { cap_object.fleet(:list) }

    context 'when a fleet client is setup' do
      before { cap_object.fleet_client }

      it "passes the fleet operation to the client" do
        expect(cap_object.fleet_client).to receive(:list)
        subject
      end
    end

    context 'otherwise' do
      it 'complains bitterly' do
        raise "This test prompts for a password for some resaon"
        expect { subject }.to raise_error FleetCaptain::FleetClient::ConnectionError
      end
    end
  end

  describe '#new_services', :vcr do
    include_context 'ssh connection established'

    before do
      subject.fleet_client = fleet_client
    end

    it 'should include units in the fleet file not on the cluster' do
      expect(subject.new_services).to include FleetCaptain::Service['hello_world']
    end
  end

  describe '#changed_services', :live do
    include_context 'ssh connection established'

    let(:truebox) { FleetCaptain::Service['truebox'] }

    before do
      subject.fleet_client = fleet_client
      subject.fleet(:submit, truebox)
      truebox.start = [run: '/bin/bash false']
    end

    it 'should list changed units' do
      expect(subject.changed_services).to include FleetCaptain::Service['truebox']
    end
  end

  describe '#stale_services'

  describe '#new_services' do
    subject { cap_object.new_services }
    it "contains any service that is not already listed in the fleet" do
      allow(cap_object).to receive(:fleet).with(:list).and_return(Set.new)
      expect(subject).to include(*cap_object.services)
    end
  end

  describe '#all_services'

  describe '#services' do
    subject { cap_object.services }
    it "contains only FleetCaptain::Service objects" do
      subject.each do |service|
        expect(service).to be_instance_of FleetCaptain::Service
      end
    end

    it 'contains objects defined only in the Fleetfile' do
      expect(subject.length).to eq 1
    end
  end

end
