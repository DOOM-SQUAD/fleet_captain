require 'active_support/core_ext/object/blank'

require 'fleet_captain/available_methods'

module FleetCaptain
  class DockerError < StandardError; end
  class ServiceNotRegistered < StandardError; end

  autoload :DockerClient, 'fleet_captain/docker_client'
  autoload :FleetClient,  'fleet_captain/fleet_client'
  autoload :AwsClient,    'fleet_captain/aws_client'
  autoload :DSL,          'fleet_captain/dsl'
  autoload :Service,      'fleet_captain/service'
  autoload :UnitFile,     'fleet_captain/unit_file'

  def self.command(&block)
    FleetCaptain::DSL.module_eval(&block)
  end

  def self.cloud_client
    AwsClient
  end

  def self.container_client
    DockerClient
  end

  def self.services
    Service.services
  end

  def self.fleet_eval(fleetfile_contents)
    DSL.send(:eval, fleetfile_contents)
    services
  end

  def self.fleetfile(filename = 'Fleetfile')
    fleet_eval(File.read(filename))
  end

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
