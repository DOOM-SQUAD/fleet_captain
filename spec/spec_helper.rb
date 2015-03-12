require 'fleet_captain'
require 'vcr'

Dir[File.join(__dir__, "support/**/*.rb")].each { |f| require f }

ENV['DOCKER_HOST'] = 'http://192.168.59.103:2376'
ENV['DOCKER_CERT_PATH'] = '/Users/you/.boot2docker/certs/boot2docker-vm'
ENV['FLEET_HOST'] = 'ec2-54-146-31-143.compute-1.amazonaws.com'

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
    WebMock.disable!
  end

  c.after(:example, live: true) do
    VCR.turn_on!
    WebMock.enable!
  end

  c.after(:example, transaction: true) do |example|
    next unless example.metadata[:live] || VCR.current_cassette.send(:previously_recorded_interactions).empty?

    VCR.eject_cassette
    VCR.turn_off!
    WebMock.disable!
    fleet_client.nuke!
    WebMock.enable! 
    VCR.turn_on!
  end
end
