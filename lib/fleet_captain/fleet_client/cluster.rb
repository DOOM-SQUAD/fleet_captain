require 'forwardable'

module FleetCaptain
  class FleetClient
    class Cluster
      extend Forwardable

      attr_reader :connection, :cluster_name

      def_delegators :connection, :connect, :client, :connected?

      def initialize(cluster_name, connection)
        @cluster_name = cluster_name
        @connection   = connection
      end

      def actual
        return @actual if @actual
        connect(instance_ips.values.first)
        @actual = instance_ips[lead_machine_ip]
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
        client.list_machines['node']['nodes'].map { |machine|
          machine['nodes'].map { |machine_node|
            JSON.parse(machine_node['value'])
          }
        }.flatten
      end

      private

      def lead_machine_ip
        return @lead_machine if @lead_machine
        res           = Faraday.new(url: 'http://localhost:10002').get('/v2/admin/machines')
        machines      = JSON.parse(res.body)
        machine_spec  = machines.find { |machine| machine.fetch('state', nil) == 'leader' }
        @lead_machine = Addressable::URI.parse(machine_spec['clientURL']).host
      end

      def instance_ips
        @instances ||= FleetCaptain.cloud_client.new(cluster_name).ip_addresses
      end
    end
  end
end
