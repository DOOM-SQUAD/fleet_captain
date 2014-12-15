require 'fleet-api'
require 'forwardable'

module FleetCaptain
  class FleetClient
    extend Forwardable

    def_delegators :start, :stop, :unload, :destroy, :status, :load, :@client

    def initialize(endpoint)
      @client = Fleet.new(fleet_api_url: endpoint)
    end

    def list
      @client.list_units
    end
  end
end
