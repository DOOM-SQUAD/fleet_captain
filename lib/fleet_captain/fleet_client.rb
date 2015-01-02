require 'fleet'
require 'forwardable'
require 'net/ssh'
require 'thread'
require 'sshkit/dsl'

module FleetCaptain
  class FleetClient
    class ConnectionError < StandardError; end
    extend Forwardable

    attr_reader :actual, :client, :queue, :cluster

    def_delegators :client, :start, :stop, :unload, :destroy, :status, :load

    def initialize(cluster, fleet_endpoint: "http://localhost:10001",
                           key_file: '~/.ssh/id_rsa')
      @cluster  = cluster 
      @client   = Fleet.new(fleet_api_url: fleet_endpoint, adapter: :excon)
      @key_file = key_file
      @queue    = Queue.new
    end

    def connected?
      @connected
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

    def connect(host = nil)
      begin
        establish_ssh_tunnel!(host || @actual)
        loop until queue.pop
      rescue Exception
        # Yes I really want a rescue Exception here as Queue raises a Fatal
        # if there are no other threads.
        raise ConnectionError, "SSH Connection Error to Fleet actual"
      end

      @connected = true
      self
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
        session.loop { puts 'hi'; true }
      end
    end

    # get the machine list from the etcd cluster
    def lead_machine
      return @lead_machine if @lead_machine
      res      = Faraday.new(url: 'http://localhost:10002').get('/v2/admin/machines')
      machines = JSON.parse(res.body)

      @lead_machine = machines.find { |machine| machine.fetch('state', nil) == 'leader' }
    end

    def list
      connect unless connected?
      response = @client.list_units
      Set.new(response['node']['nodes'].map { |unit|
        service_from_unit(unit)
      })
    end

    # Node key has a nodes key, which has a list of machines
    # Every machine has a nodes key, which is a list of units
    # Every unit has a value key, which is what we want
    # Fuck you.
    def machines
      connect unless connected?
      @client.list_machines['node']['nodes'].map { |machine|
        machine['nodes'].map { |machine_node|
          JSON.parse(machine_node['value'])
        }
      }.flatten
    end

    def submit(service)
      connect unless connected?
      @client.create_unit(service.unit_hash, service.to_unit)
    end

    private

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
