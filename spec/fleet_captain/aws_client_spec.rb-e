require 'spec_helper'

describe FleetCaptain::AwsClient do
  let(:local_template) { File.expand_path(__dir__ + '/../fixtures/core_os_template.json') }

  subject do
    described_class.new('Test Stack', test: 'true') do |c|
      c.config.template_url = local_template
    end
  end 

  it { should respond_to :instance_type }
  it { should respond_to :cluster_size }
  it { should respond_to :discovery_url }
  it { should respond_to :advertised_ip_address }
  it { should respond_to :allow_ssh_from }
  it { should respond_to :key_pair }

  it { should respond_to :instance_type= }
  it { should respond_to :cluster_size= }
  it { should respond_to :discovery_url= }
  it { should respond_to :advertised_ip_address= }
  it { should respond_to :allow_ssh_from= }
  it { should respond_to :key_pair= }

  describe '#instance_type' do
    it 'rejects unallowed instance types' do
      expect { subject.instance_type = 'm3.extra_tasty_crispy' }
        .to raise_error ArgumentError, /not allowed/
    end

    it 'actually plays nice if you do' do
      subject.instance_type = 'm3.xlarge'
      expect(subject.instance_type).to eq 'm3.xlarge'
    end

    it 'gets the default if unset' do
      expect(subject.instance_type).to eq 'm3.medium'
    end
  end

  describe '#cluster_size' do
    it 'rejects out of range numeric types' do
      expect { subject.cluster_size = 99 }
        .to raise_error ArgumentError, /out of range/
    end

    it 'rejects non numeric types' do
      expect { subject.cluster_size = 'really big' }
        .to raise_error ArgumentError, /non-numeric/
    end
  end

  describe '#to_aws_params' do
    let(:expected_params) { {
      stack_name: 'Test Stack',
      template_url: local_template,
      parameters: [
        { parameter_key: 'InstanceType', parameter_value: 'm3.medium' },
        { parameter_key: 'ClusterSize',  parameter_value: '3' }, 
        { parameter_key: 'DiscoveryURL', parameter_value: 'http://something/DEADBEEF' },
        { parameter_key: 'AdvertisedIPAddress', parameter_value: 'private' },
        { parameter_key: 'AllowSSHFrom', parameter_value: '0.0.0.0/0' },
        { parameter_key: 'KeyPair', parameter_value: 'my_key_pair' } ],
      tags: [
        { key: 'test', value: 'true' }
      ]
      }
    }

    it 'returns correct aws params' do
      subject.discovery_url = 'http://something/DEADBEEF'
      subject.key_pair = 'my_key_pair'
      expect(subject.to_aws_params).to eq expected_params
    end
  end

  context 'calling cloud formation template' do
    subject { described_class.new('test_stack', test: 'value') }

    describe 'when the parameters are present' do
      before do
        subject do |c|
          c.instance_type = 'm3.large'
        end
      end

      it 'provisions via ec2' do
        subject.discovery_url = 'DEADBEEF'
        subject.key_pair = 'my_key_pair'
        expect(subject.client).to receive(:create_stack).with(subject.to_aws_params)
        subject.provision!
      end
    end

    describe 'when parameters are not correct' do
      before do
        subject do |c|
          c.instance_type = 'vr.extra_tasty_crispy'
        end
      end

      it 'fails to provision' do
        expect { subject.provision! }.to raise_error ArgumentError
      end
    end
  end
end
