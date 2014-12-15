require 'spec_helper'

describe Capistrano::FleetCaptain do
  describe '#docker' do
    it 'should be a fleetcaptain client' do
      expect(subject.docker).to be_a FleetCaptain::Client
    end
  end
end
