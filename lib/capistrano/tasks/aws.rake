require 'active_support/core_ext/hash'

namespace :aws do
  def strategy
    @strategy ||= Capistrano::FleetCaptain.new(self, fetch(:docker_strategy, Capistrano::FleetCaptain::DefaultStrategy))
  end

  task :connect do
    strategy.aws_setup(fetch(:application), fetch(:aws_tags))
  end

  task :provision do
    run_locally do
      strategy.provision do |cloud|
        cloud.key_pair              = fetch(:key_pair)
        cloud.discovery_url         = fetch(:discovery_url)
        cloud.instance_type         = fetch(:instance_type, nil)
        cloud.cluster_size          = fetch(:cluster_size, nil)
        cloud.advertised_ip_address = fetch(:advertised_ip, nil)
        cloud.allow_ssh_from        = fetch(:allow_ssh_from, nil)
      end
    end
  end
end
