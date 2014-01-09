# encoding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "bandiera/version"

Gem::Specification.new do |spec|
  spec.name          = "bandiera"
  spec.version       = Bandiera::VERSION
  spec.authors       = ["Darren Oakley","Andrea Fiore"]
  spec.email         = ["webapplications@macmillan.co.uk"]
  spec.description   = "Bandiera is a simple, stand-alone feature flagging service that is not tied to any existing web framework or language."
  spec.summary       = "Simple feature flagging."
  spec.homepage      = "https://github.com/nature/bandiera"
  spec.license       = "GPL-3"

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = Dir.glob("spec/*_spec.rb")
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "shotgun"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "pry"

  spec.add_dependency "rake"
  spec.add_dependency "sequel"
  spec.add_dependency "mysql2"
  spec.add_dependency "sinatra"
  spec.add_dependency "rack-flash3"
  spec.add_dependency "typhoeus"
end
