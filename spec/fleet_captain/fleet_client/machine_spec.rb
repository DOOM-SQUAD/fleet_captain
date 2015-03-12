require 'spec_helper'

describe FleetCaptain::FleetClient::Machine do
 
  subject { described_class.new('28124cbd34ec4bf8b6937c2b477a5a87') }

  describe '#leader?' do
    specify { expect(subject.leader?).to be false }
  end
  
  describe '#follower?' do
    specify { expect(subject.follower?).to be true }
  end

  describe '#private_ip' do
    specify { expect(subject.private_ip).to eq '10.171.85.108' }
  end

  describe '#public_ip' do
    specify { expect(subject.public_ip).to eq '54.146.31.143' }
  end

  describe '#metadata' do
    specify { expect(subject.metadata).to eq '' }
  end

  describe '.actual' do
    specify { expect(described_class.actual).to be_a FleetCaptain::FleetClient::Machine }
  end
end
