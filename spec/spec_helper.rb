require 'fleet_captain'
require 'vcr'

Dir[File.join(__dir__, "support/**/*.rb")].each { |f| require f }

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
