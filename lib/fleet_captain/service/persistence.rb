module FleetCaptain
  class Service
    class PersistenceError < StandardError; end

    class Persistence
      attr_reader :service, :client

      def initialize(service, client)
        @service = service
        @client = client
      end

      def persisted?
        client.exists?(service)
      end

      def save(sync: false)
        if sync
          client.submit!(service)
        else
          client.submit(service)
        end
      end

      def save!
        raise PersistenceError unless save
      end

      def reload
        if stale?
          client.get_by_name(service)
          @service.update(@service)
        end
      end

      def stale?
        begin
          client.get(service) and false
        rescue Fleet::NotFound
          true
        end
      end
    end
  end
end
