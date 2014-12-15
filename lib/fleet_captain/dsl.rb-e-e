require 'set'
require 'securerandom'
require 'fleet_captain/commands/docker'
require 'active_support/configurable'
require 'active_support/core_ext/hash'

# Type=
# RemainAfterExit=
# GuessMainPID=
# PIDFile=
# BusName=
# BusPolicy=
# ExecStart=
# ExecStartPre=, ExecStartPost=
# ExecReload=
# ExecStop=
# ExecStopPost=
# RestartSec=
# TimeoutStartSec=
# TimeoutStopSec=
# TimeoutSec=
# WatchdogSec=
# Restart=
# SuccessExitStatus=
# RestartPreventExitStatus=
# RestartForceExitStatus=
# PermissionsStartOnly=
# RootDirectoryStartOnly=
# NonBlocking=
# NotifyAccess=
# Sockets=
# StartLimitInterval=, StartLimitBurst=
# StartLimitAction=
# FailureAction=
# RebootArgument=

module FleetCaptain
  def self.command(&block)
    FleetCaptain::DSL.module_eval(&block)
  end

  def self.services
    Service.services
  end

  def self.fleetfile(filename)
    DSL.send(:eval, File.read(filename))
    services
  end

  module DSL
    extend self

    def service(container, &block)
      service = FleetCaptain::Service.new(container, &block)
      FleetCaptain.services << service
      service
    end

    def container(container)
      @default_container = container
    end

    def default_container
      @default_container
    end
  end

  class Service
    include ActiveSupport::Configurable

    config_accessor :default_before_start do
      [:kill, :rm, :pull]
    end

    config_accessor :default_before_stop do
      [:stop]
    end

    config_accessor :default_after_start do
      ["cap fleet:available[%n]"]
    end

    config_accessor :default_after_stop do
      ["cap fleet:unavailable[%n]"]
    end

    def self.reset
      @services = Set.new
    end

    def self.services
      @services ||= Set.new
    end

    def self.[](key)
      services.find { |s| s.name == key || s.name == key + "@" }
    end

    def self.command_parser
      Commands::Docker
    end

    attr_reader :name

    def initialize(service_name, &block)
      @name = service_name 
      @instances = 1
      @command_parser = self.class.command_parser.new(self)
      @before_start   = to_command(self.config.default_before_start)
      @before_stop    = to_command(self.config.default_before_stop)
      @after_start    = to_command(self.config.default_after_start)
      @after_stop     = to_command(self.config.default_after_stop)

      instance_eval(&block) if block_given?
    end

    def container(container = nil)
      @container = container unless container.nil?
      @container || FleetCaptain::DSL.default_container
    end

    def instances(count)
      @instances = count
      @name = name + "@" if @instances > 1
      @instances
    end

    def container_name
      @container_name ||= (name.chomp("@") + "-" + SecureRandom.hex(3))
    end

    def template?
      @instances > 1
    end

    def description(desc)
      @description = desc
    end

    # Commands:
    #
    # Anyhwere a command is referenced in a service, it is expected to conform
    # to these expectations:
    #
    # * If a symbol is passed then it is considered a container command
    # * If a string is passed, it is considered a full-fledged shell command
    #
    def after_start(*commands)
      @after_start = to_command(commands)
    end

    def after_stop(*commands)
      @after_stop = to_command(commands)
    end

    def before_start(*commands)
      @before_start = to_command(commands)
    end

    def before_stop(*commands)
      @before_stop = to_command(commands)
    end

    def start(command)
      @start_command = to_command(command)
    end

    def stop(command)
      @stop_command = to_command(command)
    end

    def reload(*commands)
      @reload = to_command(commands)
    end

    # Fleet directs restart time spans as though they were seconds.
    #
    def restart_time(seconds)
      @restart_time = seconds
    end

    def machine_id(machine_id)
      @machine_id = machine_id
    end

    def machine_of(services_or_role)
      @machine_of = services_or_role
    end

    # Services are built based on json output.  This is the hash used to
    # describe that json.
    #
    def to_hash
      {
      "Unit" => {
        "Description"   => @description,
        "Name"          => @name,
        "ExecStart"     => @start_command,
        "ExecStartPre"  => @before_start,
        "ExecStartPost" => @after_start,
        "RestartSec"    => @restart_time,
        "ExecStop"      => @stop_command,
        "ExecStopPre"   => @before_stop,
        "ExecStopPost"  => @after_stop,
        "ExecReload"    => @reload
      }.compact,
      
      "X-Fleet" => {
        machine
      }
    end

    def to_command(command)
      case command
      when String
        [command]
      when Symbol, Hash
        [@command_parser.to_command(command)].flatten
      when Array
        command.map { |v| to_command(v) }.flatten
      end
    end

  end
end
