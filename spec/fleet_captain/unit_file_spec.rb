require 'spec_helper'
require 'active_support/core_ext/string/strip'

describe FleetCaptain::UnitFile do
  describe '.create' do
    let(:unit_file) { <<-UNIT.strip_heredoc
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
    }

    subject { FleetCaptain::UnitFile.parse(unit_file) }

    it 'creates a FleetCaptain::Service object from a unit file' do
      is_expected.to be_a FleetCaptain::Service
    end

    it 'round trips the unit file successfully' do
      expect(subject.to_unit).to eq unit_file
    end

    it 'matches the sha' do
      expect(subject.unit_hash).to eq Digest::SHA1.hexdigest(unit_file)
    end
  end
end
