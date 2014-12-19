require 'set'
require 'securerandom'
require 'fleet_captain/commands/docker'
require 'active_support/configurable'
require 'active_support/core_ext/hash'
require 'fleet'

module FleetCaptain
  class Service
    def self.services
      @services ||= Set.new
    end

    def self.[](key)
      services.find { |s| s.name == key || s.name == key + "@" }
    end

    def self.command_parser
      Commands::Docker
    end

    attr_accessor :container, :hash_slice_length, :instances, :name

    def initialize(service_name, hash_slice_length = -1)
      @name = service_name
      @instances = 1
      @command_parser = self.class.command_parser.new(self)
      @hash_slice_length = hash_slice_length
    end

    def container_name
      name_hash = unit_hash[0..hash_slice_length]
      @container_name ||= name.chomp("@") + "-" + name_hash
    end

    def template?
      @instances > 1
    end

    def method_missing(directive, *values, &block)
      ivar_name = directive.to_s.chomp("=")
      if FleetCaptain.available_methods.include? ivar_name
        instance_variable_set :"@#{ivar_name}", to_command(values)
      else
        super(directive, *values, &block)
      end
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
            memo[k] = instance_variable_get :"@#{k.underscore}" 
          }.compact
        end
      }.select { |k,v| true if v.present? }
    end

    def to_unit
      Fleet::ServiceDefinition.new(@name, to_hash).to_unit['Raw']
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
