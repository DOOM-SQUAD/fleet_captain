require 'fleet'
require 'forwardable'
require 'net/ssh'
require 'thread'

module FleetCaptain
  class FleetClient
    class ConnectionError < StandardError; end
    extend Forwardable

    attr_reader :actual, :client, :queue

    def_delegators :client, :start, :stop, :unload, :destroy, :status, :load

    def initialize(actual, fleet_endpoint: "http://localhost:10001",
                           key_file: '~/.ssh/bork-knife-ec2.pem')
      @actual   = actual 
      @client   = Fleet.new(fleet_api_url: fleet_endpoint, adapter: :excon)
      @key_file = key_file
      @queue    = Queue.new
    end

    def connected?
      @connected
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

    def establish_ssh_tunnel!
      @tunnel = Thread.new do
        session = Net::SSH.start(actual, 'core', keys: @key_file)
        session.forward.local(10001, "localhost", 4001)
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
