# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'fleet_captain/version'

Gem::Specification.new do |spec|
  spec.name          = "fleet_captain"
  spec.version       = FleetCaptain::VERSION
  spec.authors       = ["Stephen Prater"]
  spec.email         = ["me@stephenprater.com"]
  spec.summary       = %q{Deploy applications with Capistrano to Docker on CoreOS}
  spec.description   = %q{Enable capistrano hooks and deploy for ruby docker applications running in a CoreOS cluster}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "capistrano", "~> 3.2"
  spec.add_dependency "aws-sdk"
  spec.add_dependency "activesupport", "~> 4"
  spec.add_dependency "docker-api"
  spec.add_dependency "fleet-api"
  spec.add_dependency "activesupport"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "vcr", "~> 2.9"
end
