shared_context 'units' do
  let(:falsebox) { FleetCaptain::Service.new('falsebox') do |s|
      s.after    = 'docker.service'
      s.requires = 'docker.service'
      s.start    = { run: '/bin/bash false' }
      s.description = "Imagine bash returning false on a human face forever."
    end
  }

  let(:runbox) { FleetCaptain::Service.new('runbox') do |s|
      s.after = 'docker.service'
      s.requires = 'docker.service'
      s.container = 'busybox'
      s.failable_before_start = :stop
      s.failable_before_start_concat :rm
      s.start = [run: '/bin/sh -c "while true; do echo \'Hit CTRL+C\'; sleep 1; done"']
      s.description = "The box which runs"
    end
  }

  let(:truebox) { FleetCaptain::Service.from_unit name: 'truebox', text: <<-UNIT_FILE.strip_heredoc
                  [Unit]
                  Description=The box of truth.
                  After=docker.service
                  Requires=docker.service
                  
                  [Service]
                  ExecStart=/usr/bin/docker run --name truebox-1 /bin/bash true
                  UNIT_FILE
               }

end
