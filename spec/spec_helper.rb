require 'fleet_captain'
require 'vcr'

Dir[File.join(__dir__, "support/**/*.rb")].each { |f| require f }

VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :excon, :faraday, :webmock
  c.configure_rspec_metadata!
  c.filter_sensitive_data('<AWS_ACCESS_ID>') { ENV.fetch('AWS_ACCESS_KEY_ID', 'NO.') }
  c.filter_sensitive_data('<AWS_SECRET_KEY>') { ENV.fetch('AWS_SECRET_ACCESS_KEY', 'NO.') }
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
