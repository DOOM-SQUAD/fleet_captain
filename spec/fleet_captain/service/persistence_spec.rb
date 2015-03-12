require 'spec_helper'

describe FleetCaptain::Service::Persistence do
  include_context 'ssh connection established'
  include_context 'units'

  subject { nil }

  describe 'persisted?', :vcr, :transaction do
    context 'when a serivce has not been submitted' do
      it 'is false' do
        expect(falsebox.persisted?).to be false
      end
    end
    
    context 'when a serivce has been submitted' do
      before { falsebox.save }

      it 'is true' do
        expect(falsebox.persisted?).to be true
      end
    end
  end


  describe 'save', :vcr, :transaction do
    it 'submits the service unit to the fleet' do
      expect { falsebox.save }
      .to change { falsebox.persisted? }
      .from(false)
      .to(true)
    end
  end


  describe 'reload', :live, :transaction do
    before do
      falsebox.save(sync: true)
    end

    it 'reconstitues the unit from the cluster' do
      falsebox.start = [run: '/usr/bin/bash true']

      expect { falsebox.reload }
      .to change { falsebox.start }
      .from(["/usr/bin/docker run --name falsebox-cb3b5d0 /usr/bin/bash true"])
      .to(["/usr/bin/docker run --name falsebox-cb3b5d0 /usr/bin/bash false"])
    end
  end


  describe 'stale?', :vcr, :transaction do
    before do
      falsebox.start = [run: '/bin/bash true']
      falsebox.save(sync: true)
      falsebox.start = [run: '/bin/bash false']
    end

    it 'returns true if the cluster and the fleetfile do not match' do
      expect(falsebox.stale?).to be true
    end
  end
end
