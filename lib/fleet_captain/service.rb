require 'set'
require 'securerandom'
require 'active_support/configurable'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/module/aliasing'
require 'active_support/core_ext/class/attribute'
require 'active_model/attribute_methods'
require 'active_model/dirty'
require 'forwardable'

require 'fleet'

require 'fleet_captain/commands/docker'
require 'fleet_captain/commands/parser'
require 'fleet_captain/service/attributes'
require 'fleet_captain/service/persistence'

module FleetCaptain
  class Service
    class ServiceNotFound < StandardError; end

    include ActiveModel::AttributeMethods
    include ActiveModel::Dirty
    include FleetCaptain::Service::Attributes
    include ActiveSupport::Configurable
    extend Forwardable

    def self.services
      @services ||= Set.new
    end

    def self.[](key)
      services.find { |s| s.name == key || s.name == key + "@" }
    end

    def self.find(key)
      self[key] or raise ServiceNotFound
    end

    def self.from_unit(name: 'Unnamed', text:)
      FleetCaptain::UnitFile.parse(text, name)
    end

    config_accessor :cluster_name

    config_accessor :cluster_client do
      FleetClient.new(config.cluster_name)
    end

    # unit are assigned names based on the
    # sha1-hash of their unit file. if you have enough
    # unit files it's possible you can have a hash collision
    # in the first part of that hash. you can increase
    # this number if you find that happening.
    config_accessor(:hash_slice_length) { 6 }
    config_accessor(:container_type)    { 'docker' }

    attr_accessor :container, :instances
    attr_reader :name

    define_attribute_methods(:name)

    attribute_method_suffix '_concat'
    attribute_method_suffix '_multiple?'
    attribute_method_suffix '='
    attribute_method_affix  prefix: 'failable_', suffix: '='
    attribute_method_affix  prefix: 'failable_', suffix: '_concat'

    define_attributes(UNIT_DIRECTIVES)
    define_attributes(SERVICE_DIRECTIVES)
    define_attributes(XFLEET_DIRECTIVES)

    alias_attribute :before_start,  :exec_start_pre
    alias_attribute :start,         :exec_start
    alias_attribute :after_start,   :exec_start_post
    alias_attribute :reload,        :exec_reload
    alias_attribute :stop,          :exec_stop
    alias_attribute :after_stop,    :exec_stop_post

    def_delegators :@persister, :persisted?, :save, :reload, :stale?

    def initialize(service_name, cluster_client: nil)
      @name = service_name
      @instances = 1
      @persister = Persistence.new(self, cluster_client || self.class.cluster_client)
      yield self if block_given?
    end

    def name=(val)
      name_will_change! unless @name == val
      @name = val.chomp
    end

    def container_name
      return @container_name if @container_name

      name_hash = unit_hash[0..config.hash_slice_length]

      @container_name = if template?
        [name.chomp("@"), '-', name_hash, "-%i"].join
      else
        [name, '-', name_hash].join
      end
    end

    def service_name
      name + '.service'
    end

    def container_type
      self.class.container_type
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
      # for the purposes of set / key equality
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
          }.select { |k,v| true if v.present? }
        end
      }.select { |k,v| true if v.present? }
    end

    def to_unit
      to_service_def.to_unit['Raw']
    end

    def unit_hash
      Digest::SHA1.hexdigest(to_unit)
    end

    def to_service_def
      Fleet::ServiceDefinition.new(service_name, to_hash)
    end

    private

    def to_command(command, failable = false)
      FleetCaptain::Commands::Parser.new(self, command, failable: failable).to_command
    end
  end
end
