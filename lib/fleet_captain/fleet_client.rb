require 'fleet'
require 'forwardable'
require 'thread'
require 'addressable/uri'
require 'timeout'
require 'sshkit'
require 'sshkit/dsl'
require 'active_support/configurable'

require_relative 'fleet_client/connection'
require_relative 'fleet_client/machine'
require_relative 'fleet_client/cluster'

SSHKit::Backend::Netssh.configure do |ssh|
  ssh.connection_timeout = 30
  ssh.ssh_options = {
    user: 'core',
    keys: %w(/Users/prater/.ssh/bork-knife-ec2.pem),
    forward_agent: false,
    auth_methods: %w(publickey password)
  }
end

module FleetCaptain
  class FleetClient
    class ConnectionError < StandardError; end
    class ServiceNotRegistered < StandardError; end
    class FleetOperationError < StandardError; end
    class FleetErrorStatus < StandardError; end

    include SSHKit::DSL
    extend Forwardable

    def_delegators :connection, :client, :connected?, :connect, :sync_operation
    def_delegators :cluster, :instance_ips, :actual, :machines

    attr_reader :queue, :cluster, :host
    attr_accessor :connection

    def initialize(cluster_name)
      @cluster_name = cluster_name
      @connection   = FleetCaptain::FleetClient::Connection.new
      @cluster      = FleetCaptain::FleetClient::Cluster.new(@cluster_name, @connnection)
    end

    # Parse out the name of the lead instance for direct connections.
    #
    def destroy(service)
      connect unless connected?
      client.destroy(service.service_name)
    end

    def exists?(service)
      connect unless connected?
      loaded?(service) || list.include?(service)
    end

    def list
      connect unless connected?
      begin
        response = client.list_units
        Set.new(response['node'].fetch('nodes', []).map { |unit|
          service_from_unit(unit)
        })
      rescue Fleet::NotFound
        Set.new([])
      end
    end

    def loaded?(service)
      check_status(service, load_state: 'loaded')
    end

    def running?(service)
      check_status(service, active_state: 'active', sub_state: 'running')
    end

    # From orbit.
    #
    # This actually nukes things.  Be so careful.
    #
    def nuke!
      connect unless connected?

      begin
        list.each do |service|
          service_name = service.service_name
          client.stop(service_name)
          client.unload(service_name)
          client.destroy(service_name)
          client.delete_unit(service.unit_hash)
        end
      rescue Fleet::NotFound
        # i mean, you can nuke the wasteland all you want.
      end

      res = Faraday.new(url: 'http://localhost:10001')
      res.delete('/v2/keys/_coreos.com/fleet/job', recursive: true)
      res.delete('/v2/keys/_coreos.com/fleet/unit', recursive: true)


      on instance_ips.values do
        execute "for i in $(docker ps -aq); do echo $i; done;"
      end

      true
    end

    # In this case the client is not an asynchronous response and so
    # nil is not returned.  However, in keeping with the existing
    # interface we've provided, this method masks the response and
    # returns true.
    #
    def start(service)
      connect unless connected?
      client.start(service.service_name)
      true
    end

    def start!(service)
      start(service)
      sync_operation { running?(service) }
    end

    # As does this method.
    #
    def stop(service)
      connect unless connected?
      client.stop(service.service_name)
      true
    end

    # The client will return nil because the last statement is an if
    # statment to see if it should wait for it to become loaded
    # as we don't want to wait on it, we'll uncondtionally return true
    # and hope that update_job_target_spec would raise an error
    # if something went wrong.
    #
    def submit(service)
      connect_to_actual unless connected_to_actual?
      client.load(service.service_name, service.to_service_def)
      true
    end

    def submit!(service)
      submit(service)
      sync_operation { loaded?(service) }
    end

    def get(service)
      connect unless connected?
      response = client.send(:get, resource_path('unit', service.unit_hash))
      service_from_unit(response)
    end

    def get_by_name(service)
      connect unless connected?
      response      = client.send(:get, resource_path('job', service.service_name, 'object'))
      job_hash      = JSON.parse(response['node']['value'])
      service_hash  = job_hash['UnitHash'].map { |i| '%02x' % i }.join
      unit_response = client.send(:get, resource_path('unit', service_hash))
      service_from_unit(unit_response['node'])
    end

    def journal(service)
      status_response = client.status(service.service_name)

      puts 'attempting to journal'

      on actual do
        capture("fleetctl journal #{service.name}")
      end
    end

    # This method also returns true instead of a (probably more useful)
    # response body.
    #
    # What do we do here with these responses?
    #
    def unload(service)
      connect unless connected?
      client.unload(service.service_name)
      true
    end

    private

    def resource_path(resource, *parts)
      parts.unshift(resource).unshift('/v2/keys/_coreos.com/fleet').join('/')
    end
    
    def check_status(service, **state)
      connect unless connected?

      begin
        status_response = client.status(service.service_name)
      rescue Fleet::NotFound
        return false
      end


      state.each_pair do |key, value|
        if status_response[key] == 'failed'
          raise FleetErrorStatus, journal(service)
        elsif status_response[key] != value
          return false
        end
      end

      true
    end

    def service_from_unit(unit)
      unit_text = unit['value']

      begin
        unit_text = JSON.parse(unit_text)['Raw']
      rescue JSON::ParserError
        unit_text = JSON.parse("[#{unit_text}]").first
      end

      FleetCaptain::Service.from_unit(text: unit_text)
    end
  end
end
