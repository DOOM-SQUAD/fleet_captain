require 'spec_helper'
require 'capistrano/fleet_captain'

describe Capistrano::FleetCaptain do
  subject { Capistrano::FleetCaptain.new(self, Capistrano::FleetCaptain::DefaultStrategy) }

  describe '#docker', :vcr do
    it 'should be a fleetcaptain client' do
      expect(subject.docker_setup).to be_a ::FleetCaptain::DockerClient
    end
  end
end
