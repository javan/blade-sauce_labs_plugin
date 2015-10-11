# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'blade/sauce_labs_plugin/version'

Gem::Specification.new do |spec|
  spec.name          = "blade-sauce_labs_plugin"
  spec.version       = Blade::SauceLabsPlugin::VERSION
  spec.authors       = ["Javan Makhmali"]
  spec.email         = ["javan@javan.us"]

  spec.summary       = %q{Blade Runner plugin for Sauce Labs (saucelabs.com)}
  spec.homepage      = "https://github.com/javan/blade-sauce_labs_plugin"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "webmock", "~> 1.21.0"

  spec.add_dependency "blade"
  spec.add_dependency "faraday"
end
