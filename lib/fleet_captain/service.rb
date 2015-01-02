require 'set'
require 'securerandom'
require 'fleet_captain/commands/docker'
require 'active_support/configurable'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/module/aliasing'
require 'active_support/core_ext/class/attribute'
require 'active_model/attribute_methods'
require 'active_model/dirty'
require 'fleet'

module FleetCaptain
  class Service
    include ActiveModel::AttributeMethods
    include ActiveModel::Dirty

    def self.services
      @services ||= Set.new
    end

    def self.[](key)
      services.find { |s| s.name == key || s.name == key + "@" }
    end

    def self.command_parser
      Commands::Docker
    end

    def self.from_unit(text)
      FleetCaptain::UnitFile.parse(text)
    end

    def self.define_attributes(methods)
      methods.each do |directive|
        attr_reader directive
        
        define_method "#{directive.underscore}=" do |value|
          instance_variable_set "@#{directive.underscore}", to_command(value)
        end

        define_attribute_methods(directive)
      end
    end

    def attribute_concat(attr, *values)
      send(attr).concat(to_command(values))
    end

    attribute_method_suffix '_concat'
    define_attributes(UNIT_DIRECTIVES)
    define_attributes(SERVICE_DIRECTIVES)
    define_attributes(XFLEET_DIRECTIVES)

    attr_accessor :container, :hash_slice_length, :instances, :name

    def initialize(service_name, hash_slice_length = -1)
      @name = service_name
      @instances = 1
      @command_parser = self.class.command_parser.new(self)
      @hash_slice_length = hash_slice_length
    end

    alias_attribute :before_start,  :exec_start_pre
    alias_attribute :start,         :exec_start
    alias_attribute :after_start,   :exec_start_post
    alias_attribute :reload,        :exec_reload
    alias_attribute :stop,          :exec_stop
    alias_attribute :after_stop,    :exec_stop_post

    def container_name
      name_hash = unit_hash[0..hash_slice_length]
      @container_name ||= name.chomp("@") + "-" + name_hash
    end

    def template?
      @instances > 1
    end

    def ==(other)
      self.unit_hash == other.unit_hash
    end

    # Fleet directs restart time spans as though they were seconds.
    # Services are built based on json output.  This is the hash used to
    # describe that json.
    def to_hash
      table = {
        'Unit'    => UNIT_DIRECTIVES,
        'Service' => SERVICE_DIRECTIVES,
        'X-Fleet' => XFLEET_DIRECTIVES
      }

      {}.tap { |hash|
        table.each do |section, directives|
          hash[section] = directives.each_with_object({}) { |k, memo|
            memo[k] = send(k)
          }.compact
        end
      }.select { |k,v| true if v.present? }
    end

    def to_unit
      Fleet::ServiceDefinition.new(@name, to_hash).to_unit['Raw']
    end

    def attributes
      FleetCaptain.available_methods.each.with_object({}) do |method, memo|
        memo[method] = send(method)
      end
    end

    def unit_hash
      @unit_hash ||= Digest::SHA1.hexdigest(to_unit)
    end

    def to_command(command)
      case command
      when NilClass
        nil
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
