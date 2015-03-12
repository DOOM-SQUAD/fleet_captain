require 'monitor'
require 'net/ssh'

module FleetCaptain
  class FleetClient
    class Connection
      include ActiveSupport::Configurable
      include MonitorMixin

      config_accessor :fleet_timeout do
        10
      end

      attr_reader :client
      
      def initialize(fleet_endpoint: "http://localhost:10001",
                     key_file: '~/.ssh/id_rsa')
        super()     # necessary to set up monitor mixin.
        @client     = Fleet.new(fleet_api_url: fleet_endpoint, adapter: :excon)
        @key_file   = key_file
      end

      def ready!
        synchronize do
          @ready = true
        end
      end

      def ready?
        synchronize do
          @ready
        end
      end

      def stop!
        synchronize do
          @stop = true
        end
      end

      def stop?
        synchronize do
          @stop
        end
      end

      def clean?
        synchronize do
          @clean
        end
      end

      def clean!
        synchronize do
          @clean = true
        end
      end

      def reset!
        synchronize do
          @ready = false
          @stop = false
          @clean = false
        end
      end

      def connect_to_actual
        unless connected_to_actual?
          disconnect_ssh_tunnel!
          connect(actual)
        end
      end

      def connected_to_actual?
        @host == actual
      end

      def connect(host = @actual)
        begin
          establish_ssh_tunnel!(host)
          loop until ready?
        rescue Exception => e
          # Yes I really want a rescue Exception here as Queue raises a Fatal
          # if there are no other threads.j
          raise ConnectionError, "SSH Connection Error to Fleet actual (because #{e})"
        end

        @connected = true
        self
      end

      def connected?
        @connected
      end

      def disconnect_ssh_tunnel!
        if @tunnel
          stop!
          loop until connection.clean?
          reset!
        end
        @connected = false
      end

      def sync_operation
        begin
          Timeout.timeout(config.fleet_timeout) do
            loop until yield
          end
        rescue Timeout::Error
          raise FleetOperationError, "Operation did not complete in #{config.fleet_timeout} seconds"
        end
      end

      def establish_ssh_tunnel!(host = @actual)
        @host   = host
        Thread.abort_on_exception = true
        @tunnel = Thread.new do
          session = Net::SSH.start(host, 'core', keys: @key_file)
          session.forward.local(10001, "localhost", 4001)
          session.forward.local(10002, "localhost", 7001)
          ready!
          session.loop { break if connection.stop?; true }
          session.forward.cancel_local(10001)
          session.forward.cancel_local(10002)
          clean!
        end
      end
    end
  end
end

    
