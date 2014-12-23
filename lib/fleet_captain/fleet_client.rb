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

    def actual
      return @actual if @actual
      instances = FleetCaptain.cloud_client.new(cluster).instances
      establish_ssh_tunnel!(instances.first.public_dns_name)
      loop until queue.pop
      require 'pry'; binding.pry
      res = Faraday.new(url: 'http://localhost:10002').get('/v2/admin/machines')
      # get the machine list from the etcd cluster
      # then parse out the leader and establish a tunnel to that machine
      JSON.parse(res.body)
    end

    def connect
      begin
        establish_ssh_tunnel!
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

    def submit(service)
      connect unless connected?
      @client.create_unit(service.unit_hash, service.to_unit)
    end

    def machines
      connect unless connected?
      @client.list_machines
    end

    def list
      connect unless connected?
      response = @client.list_units
      Set.new(response['node']['nodes'].map { |unit|
        unit_text = JSON.parse(unit['value'])['Raw']
        FleetCaptain::Service.from_unit(unit_text)
      })
    end
  end
end
