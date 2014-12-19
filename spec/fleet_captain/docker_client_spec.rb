require 'spec_helper'

describe FleetCaptain::DockerClient do
  after { FleetCaptain::DockerClient.reset }
  
  describe '.local' do
    let(:docker_double) { double(verify: true) }

    context 'when docker should connect locally' do
      before do
        FleetCaptain::DockerClient.reset
        allow(ENV).to receive(:[]).with('DOCKER_HOST').and_return(nil)
        allow(FleetCaptain::DockerClient).to receive(:new).with(no_args).and_return(docker_double)
      end

      it 'creates a local connection' do
        expect(FleetCaptain::DockerClient.local).to be docker_double
      end

    end

    context 'when docker cannot connect on a socket' do
      before do
        ENV['DOCKER_HOST'] = 'tcp://192.168.59.103:2376'
        ENV['DOCKER_CERT_PATH'] = '/Users/dev/.boot2docker/certs/boot2docker-vm' 
      end

      before do
        allow(FleetCaptain::DockerClient)
          .to receive(:new)
          .with(instance_of(Docker::Connection))
          .and_return(docker_double)
      end

      it 'connects to the remote host' do
        expect(FleetCaptain::DockerClient.local).to be docker_double
      end
    end
  end

  context 'instance_methods' do
    let(:credentials) {
      {
        username:      "stephenprater",
        password:      "doobyfletcher",
        serveraddress: "https://index.docker.io/v1/",
        email:         "me@stephenprater.com"
      }
    }

    let(:docker_connection) {
      cert_path = '/Users/dev/.boot2docker/certs/boot2docker-vm' 
      host = 'tcp://192.168.59.103:2376'
      Docker::Connection.new(host,
        client_cert: File.join(cert_path, 'cert.pem'),
        client_key: File.join(cert_path, 'key.pem'),
        ssl_ca_file: File.join(cert_path, 'ca.pem'),
        scheme: 'https')
    }

    let(:docker) { FleetCaptain::DockerClient.new(docker_connection) }

    describe '#images' do
      it 'returns a list of images', :vcr do
        expect( docker.images )
          .to contain_exactly(an_instance_of(Docker::Image), an_instance_of(Docker::Image))
      end
    end

    describe '#authenticate!' do
      context 'when successfull' do
        it 'returns a docker authentication hash', :vcr do
          expect( docker.authenticate!(credentials) ).to eq credentials
        end
      end

      context 'when unsuccessful' do
        let(:bad_credentials) {
          {
            username:      "stephenprater",
            password:      "password",
            serveraddress: "https://index.docker.io/v1/",
            email:         "me@stephenprater.com"
          }
        }

        it 'raises a 401', :vcr do
          expect{ docker.authenticate!(bad_credentials) }.to raise_error Docker::Error::UnauthorizedError
        end
      end

      context 'when account does not exist' do
        let(:bad_credentials) {
          {
            username:      "stupidstupidstupidstupid",
            password:      "password",
            serveraddress: "https://index.docker.io/v1/",
            email:         "stupidstupidstupidstupidstupidstupid@stupid.stupid"
          }
        }

        it 'creates the account, but raises an error in this client', :vcr do
          expect{ docker.authenticate!(bad_credentials) }.to raise_error FleetCaptain::DockerError
        end
      end
    end

    describe '#image' do
      it 'returns a specific image', :vcr do
        expect( docker.image('hackuman/merchandiser:production') )
          .to be_a(Docker::Image)
      end
    end

    describe '#tag' do
      it 'tags an image with an additional tag', :vcr do
        id = docker.image('hackuman/merchandiser:production').id
        docker.tag('hackuman/merchandiser:production','hackuman/merchandiser:previous')
        expect( docker.image('hackuman/merchandiser:previous').id ).to eq id
      end

      context 'you tried to tag it wrong' do
        it 'raises an error', :vcr do
          expect {
            docker.tag('hackuman/merchandiser:production','previous')
          }.to raise_error FleetCaptain::DockerError, "new tag must be in repo:tag format"
        end
      end
    end

    describe "#build" do
      it 'takes a path to the docker file and builds it', :vcr do
        expect(docker.build('spec/fixtures', 'hackuman/test:thing')).to be_a Docker::Image
      end

      it 'outputs raw docker output', :vcr do
        expect { |b| docker.build('spec/fixtures', 'hackuman/test:thing', &b) }
          .to yield_control.exactly(6).times
      end
    end

    describe "#push" do
      before do
        docker.authenticate!(credentials)
      end

      it 'pushes a named image into a repo', :vcr do
        expect(docker.push('hackuman/test:thing')).to be_a Docker::Image
      end

      it 'outputs push output', :vcr do
        expect { |b| docker.push('hackuman/test:thing', &b) }
          .to yield_control.exactly(14).times
      end
    end
  end
end
