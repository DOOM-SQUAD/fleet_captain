require 'spec_helper'
require 'fleet_captain/dsl'

describe FleetCaptain::DSL do

  let(:service_name) { 'app_name' }
  let(:template_service) {
    FleetCaptain::DSL.service(service_name) do
      instances(2)
    end
  }

  let(:singleton_service) {
    FleetCaptain::DSL.service(service_name)
  }

  after { FleetCaptain::Service.services.clear }

  describe '.[]' do
    before { singleton_service }

    it 'returns an index for each service registered in a template' do
      expect(FleetCaptain::Service[service_name]).to eq singleton_service
    end

    context 'when service is updated' do
      it 'updates the service registry entry' do
        expect { singleton_service.instances = 2 }
          .to_not change { FleetCaptain::Service[service_name] }
      end
    end
  end

  describe '#template?' do
    it 'sets it as a template if there are multiple instances' do
      expect(template_service.template?).to be true
    end
  end

  describe '#name' do
    context 'when a singleton service' do
      it 'does not modify it' do
        expect(singleton_service.name).to eq service_name
      end
    end

    context 'when a template service' do
      it 'does modify it' do
        expect(template_service.name).to eq service_name + "@"
      end
    end
  end

  describe '#container_name' do
    context 'when a singleton service' do
      it 'adds a hex id to the end of the name' do
        expect(singleton_service.container_name).to match(/app_name-[0-9a-f]{6,}/)
      end
    end
    
    context 'when a template service' do
      it 'adds a hex id to the end of the name' do
        expect(template_service.container_name).to match(/app_name-[0-9a-f]{6,}/)
      end
    end
  end

  describe '#command behavior' do
    subject { FleetCaptain::DSL::ServiceFactory.build('service_name') }
    before  { FleetCaptain::DSL.container 'hackuman/test' }

    it 'add strings directly to the command list' do
      expect(subject.to_command('bundle exec rake')).to eq ['bundle exec rake']
    end

    it 'adds arrays to the command list' do
      expect(subject.to_command(['bundle exec rake', :run])).to eq [
        'bundle exec rake',
        "/usr/bin/docker run --name #{subject.container_name} hackuman/test"
      ]
    end

    it 'flattens an array of commands onto the command list' do
      expect(subject.to_command([:run, :kill])).to eq [
        "/usr/bin/docker run --name #{subject.container_name} hackuman/test",
        "/usr/bin/docker kill #{subject.container_name}"
      ]
    end
  end
end
