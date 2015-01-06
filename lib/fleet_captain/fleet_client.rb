require 'fleet'
require 'forwardable'
require 'net/ssh'
require 'thread'
require 'sshkit/dsl'

module FleetCaptain
  class FleetClient
    class ConnectionError < StandardError; end
    class ServiceNotRegistered < StandardError; end

    extend Forwardable

    attr_reader :client, :queue, :cluster

    def initialize(cluster, fleet_endpoint: "http://localhost:10001",
                           key_file: '~/.ssh/id_rsa')
      @cluster  = cluster 
      @client   = Fleet.new(fleet_api_url: fleet_endpoint, adapter: :excon)
      @key_file = key_file
      @queue    = Queue.new
    end

    # Parse out the name of the lead instance for direct connections.
    #
    def actual
      return @actual if @actual
      instances = FleetCaptain.cloud_client.new(cluster).instances
      connect(instances.first.public_dns_name)
      lead_instance = instances.find { |instance|
        lead_machine['clientURL'].include? instance.private_ip_address
      }
      lead_instance.public_dns_name
    end

    def connect(host = @actual)
      begin
        establish_ssh_tunnel!(host)
        loop until queue.pop
      rescue Exception
        # Yes I really want a rescue Exception here as Queue raises a Fatal
        # if there are no other threads.
        raise ConnectionError, "SSH Connection Error to Fleet actual"
      end

      @connected = true
      self
    end

    def connected?
      @connected
    end

    def destroy(service)
      connect unless connected?
      @client.destroy(service.name + ".service")
    end

    def disconnect_ssh_tunnel!
      @tunnel.kill
      @connected = false
    end

    def establish_ssh_tunnel!(host = @actual)
      @tunnel = Thread.new do
        session = Net::SSH.start(host, 'core', keys: @key_file)
        session.forward.local(10001, "localhost", 4001)
        session.forward.local(10002, "localhost", 7001)
        queue << :ready
        session.loop { true }
      end
    end

    def exists?(service)
      connect unless connected?
      loaded?(service) || list.include?(service)
    end

    # Get the machine list from the etcd cluster
    #
    def lead_machine
      return @lead_machine if @lead_machine
      res           = Faraday.new(url: 'http://localhost:10002').get('/v2/admin/machines')
      machines      = JSON.parse(res.body)
      @lead_machine = machines.find { |machine| machine.fetch('state', nil) == 'leader' }
    end

    def list
      connect unless connected?
      response = @client.list_units
      Set.new(response['node'].fetch('nodes', []).map { |unit|
        service_from_unit(unit)
      })
    end

    def loaded?(service)
      check_status(service, :load_state, 'loaded')
    end

    def running?(service)
      check_status(service, :active_state, 'running')
    end

    # The node key has a nodes key, which has a list of machines.
    #
    # Every machine has a nodes key, which is a list of units.
    #
    # Every unit has a value key, which is what we want.
    #
    # Because of course it does.
    #
    # It's a long story.
    #
    def machines
      connect unless connected?
      @client.list_machines['node']['nodes'].map { |machine|
        machine['nodes'].map { |machine_node|
          JSON.parse(machine_node['value'])
        }
      }.flatten
    end

    # From orbit.
    #
    # This actually nukes things.  Be so careful.
    #
    def nuke!
      list.each do |service|
        service_name = service.name + ".service"
        @client.stop(service_name)
        @client.unload(service_name)
        @client.destroy(service_name)
        @client.delete_unit(service.unit_hash)
      end
    end

    # In this case the client is not an asynchronous response and so
    # nil is not returned.  However, in keeping with the existing
    # interface we've provided, this method masks the response and
    # returns true.
    #
    def start(service)
      connect unless connected?
      @client.start(service.name + ".service")
      true
    end

    # As does this method.
    #
    def stop(service)
      connect unless connected?
      @client.stop(service.name + ".service")
      true
    end

    # The client will return nil because the last statement is an if
    # statment to see if it should wait for it to become loaded
    # as we don't want to wait on it, we'll uncondtionally return true
    # and hope that update_job_target_spec would raise an error
    # if something went wrong.
    #
    def submit(service)
      connect unless connected?
      @client.load(service.name + '.service', service.to_service_def)
      true
    end

    # This method also returns true instead of a (probably more useful)
    # response body.
    #
    # What do we do here with these responses?
    #
    def unload(service)
      connect unless connected?
      @client.unload(service.name + ".service")
      true
    end

    private

    def check_status(service, key, status)
      connect unless connected?
      begin
        status_response = @client.status(service.name + '.service')
        status_response.fetch(key, 'unknown') == status
      rescue Fleet::NotFound
        false
      end
    end

    def service_from_unit(unit)
      unit_text = unit['value']

      begin
        unit_text = JSON.parse(unit_text)['Raw']
      rescue JSON::ParserError
        unit_text = JSON.parse("[#{unit_text}]").first
      end

      FleetCaptain::Service.from_unit(unit_text)
    end

  end
end
