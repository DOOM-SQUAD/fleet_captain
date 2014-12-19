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

    def initialize(actual, fleet_endpoint, key_file = '~/.ssh/id_rsa')
      @actual  = actual 
      @key_file = key_file
      @queue = Queue.new
      @client = Fleet.new(fleet_api_url: fleet_endpoint)
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
        session.forward.local(4001, "127.0.0.1", 4001)
        queue << :ready
        session.loop { true }
      end
    end

    def list
      connect unless connected?
      @client.list_units
    end
  end
end
