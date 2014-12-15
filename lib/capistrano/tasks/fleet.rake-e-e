namespace :fleet do
  def strategy
    @strategy ||= Capistrano::FleetCaptain.new(self, fetch(:docker_strategy, Capistrano::FleetCaptain::DefaultStrategy))
  end

  def service_list
    strategy.list
  end

  task :unregister do |service|
    # i don't know what this does
  end
  
  task :register do |service|
    # i don't know what this does either
  end

  task :restart_all do
    service_list.each do |service|
      invoke :unregister, service
      invoke :restart, service
      invoke :register, service
      invoke :restarted, service
    end
  end

  task :restart do |service|
    strategy.restart(service)
    strategy.ensure_uptime(service)
  end

  task :restarted do |service|
    # notification task
  end
end
