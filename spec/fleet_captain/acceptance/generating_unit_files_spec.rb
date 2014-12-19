require 'spec_helper'

describe 'generating systemd unit files from Fleetfile' do
  let(:contents) {
    <<-CONTENTS
      container 'hackuman/test'

      service 'hello_world' do
        container 'busybox'
        description "Hello World"
        start run: ['bin/sh -c "while true; do echo Hello World; sleep 1; done"']
      end
    CONTENTS
  }

  before  { FleetCaptain.fleet_eval(contents) }
  after   { FleetCaptain.services.clear }
  
  it 'should have created a service' do
    expect(FleetCaptain.services.length).to eq 1
  end

  it 'can generate a unit file from that fleet file' do
    expect(FleetCaptain.services.first.to_unit).to eq <<-UNIT.strip_heredoc
      [Unit]
      Description=Hello World
      Name=hello_world
      After=docker.service
      Requires=docker.service

      [Service]
      ExecStart=/usr/bin/docker run --name hello_world-75283b0 busybox bin/sh -c "while true; do echo Hello World; sleep 1; done"
      ExecStartPre=/usr/bin/docker kill hello_world-75283b0
      ExecStartPre=/usr/bin/docker rm hello_world-75283b0
      ExecStartPre=/usr/bin/docker pull hello_world-75283b0
      ExecStartPost=cap fleet:available[%n]
      ExecStop=/usr/bin/docker stop hello_world-75283b0
      ExecStopPost=cap fleet:unavailable[%n]
    UNIT
  end

end
