namespace :fleet do
  def strategy
    @strategy ||= Capistrano::FleetCaptain.new(self, fetch(:fleet_strategy, Capistrano::FleetCaptain::DefaultStrategy))
  end

  task :deploy do
    %w( loading loaded
        registering registered
        updating updated
        status
        restarting restarted).each do |task|
        invoke "fleet:#{task}"
    end
  end

  task :loading do
    strategy.load_fleetfile
  end

  task :loaded do
    # inform the user
  end

  task :registering do
    new_locals = strategy.new_locally

    new_locals.each do |service|
      invoke 'register', service
    end

    invoke 'wait_for_loaded_services', new_locals

    new_locals.each do |service|
      invoke 'start', service
    end
  end

  task :wait_for_loaded_services do |services|
    loop until services.all? { |service|
      strategy.loaded?(service)
    }
  end

  task :registered do
    # inform the user
  end

  task :updating do
    strategy.changed_locally.each do |service|
      invoke 'update', service
    end
  end

  task :updated do
    # inform the user
  end

  task :status do
    strategy.stale_services.each do |service|
      warn("#{service} is running on your cluster, but is not in your Fleetfile")
    end
  end

  task :restarting do
    strategy.remote_services.each do |service|
      invoke 'restart', service
      invoke 'restarted', service
    end
  end

  task :restarted do
    #inform the user
  end

  task :unregister do |service|
    # i don't know what this does
  end
  
  task :available do |service|
    # mark the service as available in etcd
  end

  task :unavailable do |service|
    # mark the service as unaviable in etcd 
  end

  task :ensure_available do |service|
    # check to see if the service is in etcd
    # exit -1 if it isn't.
  end

  task :restart do |service|
    strategy.restart(service)
  end

  task :register do |service|
    strategy.register(service)
  end

  task :update do |service|
    strategy.stop(service)
    strategy.remove(service)
    strategy.register(service)
  end

  task :start do |service|
    strategy.start(service)
  end

  task :remove do |service|
    strategy.remove(service)
  end

  task :restarted do |service|
    # notification task
  end
end
