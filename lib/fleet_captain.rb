require 'active_support/core_ext/object/blank'

module FleetCaptain
  class DockerError < StandardError; end

  autoload :DockerClient, 'fleet_captain/docker_client'
  autoload :FleetClient,  'fleet_captain/fleet_client'
  autoload :AwsClient,    'fleet_captain/aws_client'
  autoload :DSL,          'fleet_captain/dsl'

  def self.docker_repo_url(**args)
    String.new.tap do |str|
      str << args.fetch(:repo, '')
      str << "/" if str.present?
      str << args.fetch(:user)
      str << "/"
      str << args.fetch(:name)
      str << ':'
      str << args.fetch(:tag)
    end
  end
end
