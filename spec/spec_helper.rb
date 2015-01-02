require 'fleet_captain'
require 'vcr'

Dir[File.join(__dir__, "support/**/*.rb")].each { |f| require f }

VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :excon, :faraday, :webmock
  c.configure_rspec_metadata!
  c.filter_sensitive_data('<AWS_ACCESS_ID>') { ENV['AWS_ACCESS_KEY_ID'] }
  c.filter_sensitive_data('<AWS_SECRET_KEY>') { ENV['AWS_SECRET_ACCESS_KEY'] }
end

RSpec.configure do |c|
  c.before(:example, live: true) do
    VCR.eject_cassette
    VCR.turn_off!
  end

  c.after(:example, live: true) do
    VCR.turn_on!
  end
end
