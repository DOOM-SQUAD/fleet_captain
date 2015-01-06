require 'active_support/configurable'
require 'active_support/inflector'

module FleetCaptain
  module DSL
    extend self

    def service(name, &block)
      service = FleetCaptain::DSL::ServiceFactory.build(name, &block)
      FleetCaptain.services << service
      service
    end

    def container(container)
      @default_container = container
    end

    def default_container
      @default_container
    end

    class ServiceFactory
      include ActiveSupport::Configurable

      config_accessor :default_before_start do
        [:kill, :rm, :pull]
      end

      config_accessor :default_stop do
        [:stop]
      end

      config_accessor :default_after_start do
        ["cap fleet:available[%n]"]
      end

      config_accessor :default_after_stop do
        ["cap fleet:unavailable[%n]"]
      end

      # unit are assigned names based on the
      # sha1-hash of their unit file. if you have enough
      # unit files it's possible you can have a hash collision
      # in the first part of that hash. you can increase
      # this number if you find that happening.
      config_accessor :hash_slice_length do
        6
      end

      attr_reader :service

      def self.build(name, &block)
        service = FleetCaptain::Service.new(name, hash_slice_length: config.hash_slice_length)
        service.after             = 'docker.service'
        service.requires          = 'docker.service'
        service.exec_start_pre    = config.default_before_start
        service.exec_start_post   = config.default_after_start
        service.exec_stop         = config.default_stop
        service.exec_stop_post    = config.default_after_stop
        service.container         = FleetCaptain::DSL.default_container
        new(service, &block).service
      end

      def initialize(service, &block)
        @service = service
        instance_eval(&block) if block_given?
      end

      def container(container)
        service.container = container unless container.nil?
      end

      def instances(count)
        service.instances = count
        service.name = service.name + "@" if count > 1
      end

      def description(desc)
        service.description = desc
      end

      def self.define_directives(methods)
        methods.each do |directive|
          define_method directive.underscore do |value|
            if service.send(directive.underscore).present?
              service.send("#{directive.underscore}_concat", value)
            else
              service.send("#{directive.underscore}=", value)
            end
          end
        end
      end

      define_directives(UNIT_DIRECTIVES)
      define_directives(SERVICE_DIRECTIVES)
      define_directives(XFLEET_DIRECTIVES)

      alias_method :before_start,  :exec_start_pre
      alias_method :start,         :exec_start
      alias_method :after_start,   :exec_start_post
      alias_method :reload,        :exec_reload
      alias_method :stop,          :exec_stop
      alias_method :after_stop,    :exec_stop_post
    end
  end
end
