require 'spec_helper'

describe FleetCaptain::Service do
  let(:unit_text) { <<-UNIT_FILE.strip_heredoc
    [Unit]
    Description=The box of comparison.
    After=docker.service
    Requires=docker.service

    [Service]
    ExecStart=/bin/bash test 1
    UNIT_FILE
  }

  describe '.from_unit'
  describe '.services'

  let(:service1) { FleetCaptain::Service.from_unit(name: 'compbox1', text: unit_text) }

  describe 'equality tests' do
    let(:service2) { FleetCaptain::Service.from_unit(name: 'compbox1', text: unit_text) }

    describe '#==' do
      it 'is equal because they have the same unit file context' do
        expect(service1).to eq service2
      end
    end

    describe '#eql?' do
      it 'is eql' do
        expect(service1.eql?(service2)).to be true
      end
    end
  end

  describe '#to_unit' do
    include_context 'units'

    let(:falsebox_text) { <<-UNIT_FILE.strip_heredoc
      [Unit]
      Description=Imagine bash returning false on a human face forever.
      After=docker.service
      Requires=docker.service

      [Service]
      ExecStart=/usr/bin/docker run --name falsebox-cb3b5d0 /bin/bash false
      UNIT_FILE
    }

    it 'is equal to the unit file' do
      expect(service1.to_unit).to eq unit_text
    end

    it 'works on falsebox' do
      expect(falsebox.to_unit).to eq falsebox_text
    end
  end


  describe '#unit_hash' do
    it 'is the hash of the unit file' do
      expect(service1.unit_hash).to eq Digest::SHA1.hexdigest(unit_text)
    end
  end


  describe '#attribute=' do
    it 'converts to a command on assignment' do
      service1.start = :run
      expect(service1.start).to eq ['/usr/bin/docker run --name compbox1-8b1ea1a']
    end

    it 'triggers change on assignment' do
      service1.start = :run
      expect(service1.start_changed?).to be true
    end
  end

  describe '#attribute_concat' do
    it 'assigns additional commands on concat' do
      service1.before_start_concat :stop
      service1.before_start_concat :run
      expect(service1.before_start).to eq [
        '/usr/bin/docker stop compbox1-8b1ea1a',
        '/usr/bin/docker run --name compbox1-8b1ea1a'
      ]
    end

    it 'triggers change on concat' do
      service1.before_start_concat :rm
      expect(service1.before_start_changed?).to be true
    end
  end

  describe '#attribute_multiple?' do
    it 'returns true for directives which can be called multiple times' do
      expect(service1.after_multiple?).to be true
    end
  end

  describe '#attributes' do
    it 'returns a hash of attributes' do
      expect(service1.attributes).to eq({
        'description' => 'The box of comparison.',
        'after'       => ['docker.service'],
        'requires'    => ['docker.service'],
        'name'        => 'compbox1',
        'exec_start'  => ['/bin/bash test 1']
      })
    end
  end

  describe '#container_name' do
    context 'when not a template container' do
      it 'returns a container name with the hash in the name' do
        expect(service1.container_name).to eq 'compbox1-8b1ea1a'
      end
    end

    context 'when a template container' do
      let(:service2) { FleetCaptain::Service.from_unit(name: 'compbox1', text: unit_text) }

      before { service2.instances = 2 }

      it 'returns a container with the hash and a instance identifier' do
        expect(service2.container_name).to eq 'compbox1-8b1ea1a-%i'
      end
    end
  end


  describe '#failable_attribute=' do
    it 'prefixes the compiled command with a dash' do
      service1.failable_before_start = :stop
      expect(service1.before_start).to eq ['-/usr/bin/docker stop compbox1-8b1ea1a']
    end
  end

  describe '#failable_attribute_concat' do
    it 'prefixes compiles commands with a dash' do
      service1.failable_before_start_concat :stop
      service1.failable_before_start_concat :rm
      expect(service1.before_start).to eq [
        '-/usr/bin/docker stop compbox1-8b1ea1a',
        '-/usr/bin/docker rm compbox1-8b1ea1a',
      ]
    end
  end

  describe '#hash' do
    it 'is actually the ruby hash for the unit hash string' do
      # TODO not sure how valuable this test is as it reifies the
      # implementation - but on the other hand that's exactly what we want
      expect(service1.unit_hash.hash).to eq service1.hash
    end
  end

  describe '#name=' do
    it 'triggers change on name assign' do
      service1.name = 'hello'
      expect(service1.name_changed?).to be true
    end
  end

  describe '#template?' do
    it 'is a template if it has multiple instances' do
      service1.instances = 2
      expect(service1.template?).to be true
    end
  end


  describe '#to_hash' do
    subject { service1.to_hash }

    let(:expected_hash) {
        {  "Unit" =>
          {
            "Description" => "The box of comparison.",
            "After" => ["docker.service"],
            "Requires" => ["docker.service"]
          },
            "Service" => { "ExecStart" => ["/bin/bash test 1"] },
      }
    }

    
    it { is_expected.to have_key('Unit') }
    it { is_expected.to have_key('Service') }
    it { is_expected.to_not have_key('X-Fleet') }

    it { is_expected.to eq expected_hash }

    context 'when there are three sections' do
      before do 
        service1.conflicts_concat 'service2.service'
      end
      
      it { is_expected.to have_key('X-Fleet') }
    end
  end
end
