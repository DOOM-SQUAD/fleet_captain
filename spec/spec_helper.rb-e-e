require 'fleet_captain'

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :excon, :faraday
  c.configure_rspec_metadata!
end

RSpec.configure do |c|
  c.before(:example, live: true) do
    VCR.eject_cassette
    VCR.turn_off!
  end
end
