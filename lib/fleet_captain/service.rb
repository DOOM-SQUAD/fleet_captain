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
        method_name = directive.underscore
        attr_reader method_name
        define_attribute_methods(method_name)
      end
    end

    def attribute_concat(attr, *values)
      if send("#{attr}_multiple?")
        send(attr).concat(to_command(values))
      else
        send("#{attr}=", values.first)
      end
    end

    def attribute=(attr, value)
      new_value = to_command(value)
      unless [new_value, nil].include?(send(attr))
        send("#{attr}_will_change!")
      end
      instance_variable_set "@#{attr}", new_value
    end

    def attribute_multiple?(attr)
      FleetCaptain.multi_value_directives.include?(attr)
    end

    attr_accessor :container, :hash_slice_length, :instances

    attribute_method_suffix '_concat'
    attribute_method_suffix '_multiple?'
    attribute_method_suffix '='
    define_attributes(UNIT_DIRECTIVES)
    define_attributes(SERVICE_DIRECTIVES)
    define_attributes(XFLEET_DIRECTIVES)

    alias_attribute :before_start,  :exec_start_pre
    alias_attribute :start,         :exec_start
    alias_attribute :after_start,   :exec_start_post
    alias_attribute :reload,        :exec_reload
    alias_attribute :stop,          :exec_stop
    alias_attribute :after_stop,    :exec_stop_post

    def initialize(service_name, hash_slice_length: -1)
      @name = service_name
      @instances = 1
      @command_parser = self.class.command_parser.new(self)
      @hash_slice_length = hash_slice_length
      yield self if block_given?
    end

    def name=(val)
      name_will_change! unless val == @name
      @name = val.chomp
    end

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

    def hash
      self.unit_hash.hash
    end

    def eql?(other)
      self == other
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
            memo[k] = send(k.underscore)
          }.compact
        end
      }.select { |k,v| true if v.present? }
    end

    def to_unit
      to_service_def.to_unit['Raw']
    end

    def to_service_def
      Fleet::ServiceDefinition.new(@name + '.service', to_hash)
    end

    def attributes
      FleetCaptain.available_methods.each.with_object({}) { |method, memo|
        memo[method] = send(method)
      }
    end

    def unit_hash
      Digest::SHA1.hexdigest(to_unit)
    end

    def to_command(command)
      case command
      when NilClass
        nil
      when String
        [command.chomp]
      when Symbol, Hash
        [@command_parser.to_command(command)].flatten
      when Array
        command.map { |v| to_command(v) }.flatten
      end
    end
  end
end
