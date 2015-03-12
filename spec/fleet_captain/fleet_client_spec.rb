require 'spec_helper'

describe FleetCaptain::FleetClient do
  context 'requires connecttion' do
    include_context 'ssh connection established'
    include_context 'units'
    
    subject { fleet_client }

    let(:expected_unit) {
      FleetCaptain::Service.from_unit(<<-UNIT.strip_heredoc
      [Unit]
      Description=Hello World
      
      [Service]
      ExecStart=/bin/bash -c "while true; do echo \\\"Hello, world\\\"; sleep 1; done"
      UNIT
      )
    }

    after do |example|
      next unless example.metadata[:live] || VCR.current_cassette.send(:previously_recorded_interactions).empty?

      VCR.eject_cassette
      VCR.turn_off!
      WebMock.disable!
      subject.nuke!
      WebMock.enable! 
      VCR.turn_on!
    end

    it 'connects to the fleet actual via ssh tunnel', :vcr do
      expect(fleet_client.list.first).to eq expected_unit
    end

    describe '#live_nuke', :live do
      it('nukes') { true }
    end

    describe '#nuke', :vcr do
      before do
        subject.submit(truebox)
        subject.submit(falsebox)
      end

      it 'destroys everything completely' do
        expect { subject.nuke! }
        .to change { subject.list.count }
        .from(2)
        .to(0)
      end
    end

    describe '#machines', :live do
      it 'returns a complete description of the cluster' do
        expect(subject.machines).to eq expected_hash
      end

      it 'can retrieve a list of machines' do
        expect(fleet_client.machines.length).to be 3
      end
    end

    it 'raises a connection error if the ssh tunnel cannot be established' do
      allow(fleet_client).to receive(:establish_ssh_tunnel!) do
        raise 'fatal'
      end

      expect { fleet_client.list }.to raise_error FleetCaptain::FleetClient::ConnectionError
    end

    describe '#list', :live do
      before do
        subject.submit(truebox)
        subject.submit(falsebox)
        subject.submit(runbox)
      end

      it 'retrieves a set of units on the cluster' do
        expect(fleet_client.list.size).to be 3
      end
    end

    describe '#loaded?', :vcr do

      context 'with an already loaded service' do
        before do
          subject.submit(truebox)
        end

        it "is true" do
          expect { fleet_client.loaded?(truebox) }.to become(true).within(5)
        end
      end

      context 'otherwise' do
        it "is false" do
          expect( fleet_client.loaded?(falsebox) ).to eq false
        end
      end
    end

    describe 'exists?', :vcr do
      context 'for a loaded unit' do
        before do
          subject.submit(truebox)
        end

        it 'returns true' do
          expect(subject.exists?(truebox)).to be true
        end
      end

      context 'for a running unit', :live do
        before do
          subject.submit!(runbox)
          subject.start!(runbox)
        end

        it 'returns true' do
          expect(subject.exists?(runbox)).to be true
        end
      end
    end

    describe 'running?', :vcr do
      context 'with a service currently running' do
        before do
          subject.submit!(runbox)
          subject.start(runbox)
        end

        it 'is true' do
          expect { subject.running?(runbox) }.to become(true).within(10)
        end
      end

      context 'when service is not running' do
        before do
          subject.submit!(falsebox)
        end

        it 'is false' do
          expect(subject.running?(falsebox)).to eq false
        end
      end

    end

    describe 'submit!', :vcr do
      include_context 'units'
      
      it 'submits a unit to the cluster, and waits on it' do
        fleet_client.submit!(falsebox)
        expect(fleet_client.loaded?(falsebox)).to be true
      end
    end

    describe 'submit', :vcr do
      include_context 'units'

      it 'submits a unit to the cluster' do
        fleet_client.submit(falsebox) 
        expect { fleet_client.loaded?(falsebox) }.to become(true).within(5)
      end
    end
  end

  #describe 'connect_to_actual', :live do
  #  let(:fleet_client) { FleetCaptain::FleetClient.new('Test-Stack', key_file: '~/.ssh/bork-knife-ec2.pem') }

  #  it 'submits fleet / etcd requests the the lead machine' do
  #    expect { fleet_client.connect_to_actual }
  #    .to change { fleet_client.connected_to_actual? }
  #    .from(false).to(true)
  #  end
  #end

  describe 'connect to actual', :vcr do
    let(:fleet_client) { FleetCaptain::FleetClient.new('Test-Stack', key_file: '~/.ssh/id_rsa.pub') }
    
    before do
      allow(fleet_client).to receive(:actual).and_return('54.146.31.143')
    end

    it 'will try to connect to the actual' do
      expect(fleet_client).to receive(:connect).with('54.146.31.143')
      fleet_client.connect_to_actual
    end

  end

  describe 'actual', :vcr do
    it 'dynamically determines the etcd cluster leader' do
      expect(fleet_client.actual).to eq '54.146.31.143'
    end
  end

  
  describe '#check_status' do
    let(:fleet_client) { FleetCaptain::FleetClient.new('Test-Stack', key_file: '~/.ssh/id_rsa.pub') }
    include_context 'units'

    let(:status_report) { 
      {  
         load_state:    "loaded",
         active_state:  "failed",
         sub_state:     "failed",
         unit_hash:     "7a45c171fe9464bc0c98ed8865d2147d0e505507",
         machine_state:
           {  
              "ID"       => "28124cbd34ec4bf8b6937c2b477a5a87",
              "PublicIP" => "",
              "Metadata" => nil,
              "Version"  => "" 
           }
      }
    }

    before do
      allow(fleet_client).to receive(:connected?).and_return(true)
      allow(fleet_client.client).to receive(:status).and_return(status_report)
    end

    subject { fleet_client.send(:check_status, runbox, status_query) }

    context 'when the status is a single state thing' do
      let(:status_query) { { load_state: 'loaded' } }

      it 'only checks that' do
        expect(subject).to be true
      end
    end

    context 'when the status is composed state thing' do
      let(:status_query) { { active_state: 'active', sub_state: 'running' } }
      
      it 'checks both of them' do
        status_report.merge!(active_state: 'active', sub_state: 'running')
        expect(subject).to be true
      end
    end

    context 'when the status include a failure' do
      let(:status_query) { { load_state: 'loaded' } }
      
      context 'when it is not relevant' do
        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when it is relevant' do
        before do
          allow(fleet_client).to receive(:journal).and_return('something wrong')
        end
      
        let(:status_query) { { load_state: 'loaded', active_state: 'active' } }

        it 'raises an exception' do
          expect{ subject }.to raise_error FleetCaptain::FleetClient::FleetErrorStatus, "something wrong"
        end
      end
    end
  end
end
