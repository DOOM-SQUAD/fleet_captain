require 'spec_helper'
require 'fleet_captain/dsl'
   
describe FleetCaptain::Commands::Docker do
  let(:service_stub) {
    instance_double("FleetCaptain::Service",
                    container_name: 'service-name-001',
                    container: 'hackuman/test')
  }

  subject { FleetCaptain::Commands::Docker.new(service_stub) }

  it 'convert symbols into docker commands' do
    expect(subject.to_command(:run)).to eq ["/usr/bin/docker run --name service-name-001 hackuman/test"]
  end

  it 'turns a hash into arguments' do
    expect(subject.to_command(run: { p: '80:80' })).to eq [
      "/usr/bin/docker run --name service-name-001 -p 80:80 hackuman/test"
    ]
  end

  it 'turns a hash with true keys into flags' do
    expect(subject.to_command(run: { i: true, t: true })).to eq [
      "/usr/bin/docker run --name service-name-001 -i -t hackuman/test"
    ]
  end

  it 'turns a hash into arguments with the correct number of prefix dashes' do
    expect(subject.to_command(run: {'env-file' => 'test.env' })).to eq [
      "/usr/bin/docker run --name service-name-001 --env-file test.env hackuman/test"
    ]
  end

  it 'turns a hash into arguments with the correct number of prefix dashes' do
    expect(subject.to_command(run: {env_file: 'test.env' })).to eq [
      "/usr/bin/docker run --name service-name-001 --env-file test.env hackuman/test"
    ]
  end

  it 'turns a hash with a string value into an entry point' do
    expect(subject.to_command(run: '/bin/bash')).to eq [
      "/usr/bin/docker run --name service-name-001 hackuman/test /bin/bash"
    ]
  end

  it 'supports both arguments and alternate entry points' do
    expect(subject.to_command(run: ['/bin/bash', { p: '80:80' }])).to eq [
      "/usr/bin/docker run --name service-name-001 -p 80:80 hackuman/test /bin/bash"
    ]
  end

  it 'supports both arguments and alternate entry points' do
    expect(subject.to_command(run: { p: '80:80',  v: '/mount:/mount' })).to eq [
      "/usr/bin/docker run --name service-name-001 -p 80:80 -v /mount:/mount hackuman/test"
    ]
  end
end

