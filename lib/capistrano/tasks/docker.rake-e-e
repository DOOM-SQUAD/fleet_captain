namespace :docker do

  def strategy
    @strategy ||= Capistrano::FleetCaptain.new(self, fetch(:docker_strategy, Capistrano::FleetCaptain::DefaultStrategy))
  end

  def container_tag(tag)
    FleetCaptain.docker_repo_url(
      repo: fetch(:docker_repo, ''),
      user: fetch(:docker_user),
      name: fetch(:docker_name, fetch(:application)),
      tag:  tag 
    )
  end

  def production_tag
    container_tag(fetch(:deploy_tag))
  end

  def rollback_tag
    container_tag(fetch(:rollback_tag, 'previous'))
  end

  task :start do
    strategy.verify
  end

  task :retag do
    strategy.rollback_tag(production_tag, rollback_tag)
  end

  task :build do
    strategy.build(production_tag)
  end

  task :release do
    # will push "rollback" tag to the repo leaving it tagged as "production"
    strategy.release(rollback_tag)
    
    # will push "production" tag to the repo, replacing the current production
    strategy.release(production_tag)
  end
end
