namespace :fleet_captain do
  desc 'Obtain a discovery url from the etcd endpoint'
  task :discovery do
    puts open('https://discovery.etcd.io/new').read
  end

  desc 'Start a deployment, make sure server(s) ready.'
  task :starting do
    invoke 'docker:start'
  end

  desc 'Started'
  task :started do
  end

  desc 'Connect AWS CloudFormation Client'
  task :connect do
    invoke 'aws:connect'
  end

  desc 'Provision CoreOS / Docker ready servers'
  task :provisioning do
    invoke 'aws:provision'
  end

  desc 'Done provisioning'
  task :provisioned do
    #notify the user
  end

  desc 'Build Docker Container'
  task :building do
    # retag the last release as "previous"
    invoke 'docker:retag'
    # tag the current release as 'deploy_tag'
    invoke 'docker:build'
  end

  desc 'Built docker Container'
  task :built do
  end

  desc 'Update server(s) by setting up a new release.'
  task :updating do
    # push the current relase to docker hub or other repo
    invoke 'docker:push'
  end

  desc 'Updated'
  task :updated do
    # inform the user
  end

  desc 'Revert server(s) to previous release.'
  task :reverting do
    # get the previously deployed tag from elastic beanstalk
    invoke 'fleet:revert', previous
  end

  desc 'Reverted'
  task :reverted do
    #inform the user
  end

  desc 'Publish the release.'
  task :publishing do
    invoke 'fleet:deploy'
  end

  desc 'Published'
  task :published do
    #inform the user
  end

  desc 'Finish the deployment, clean up server(s).'
  task :finishing do
    # inform the user
  end

  desc 'Finish the rollback, clean up server(s).'
  task :finishing_rollback do
    # inform the user
  end

  desc 'Finished'
  task :finished do
    #inform the user
  end

  desc 'Rollback to previous release.'
  task :rollback do
    %w{ starting started
        reverting reverted
        publishing published
        finishing_rollback finished }.each do |task|
      invoke "fleet_captain:#{task}"
    end
  end

  desc 'Deploy a new release using docker.'
  task :deploy do
    %w{ starting started
        building built
        updating updated
        publishing published
        finishing finished }.each do |task|
      invoke "fleet_captain:#{task}"
    end
  end

  task :setup do
    %w{ connect provisioning provisioned }.each do |task|
      invoke "fleet_captain:#{task}"
    end
  end
end

desc 'Deploy a new release with docker.'
task :deploy do
  invoke "fleet_captain:deploy"
end

namespace :deploy do
  task :setup do
    invoke "fleet_captain:setup"
  end
end
