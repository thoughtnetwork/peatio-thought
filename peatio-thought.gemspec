# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "peatio/thought/version"

Gem::Specification.new do |spec|
  spec.name          = "peatio-thought"
  spec.version       = Peatio::Thought::VERSION
  spec.authors       = ["Andrew@Thought"]
  spec.email         = ["andrew@thought.live"]

  spec.summary       = "Peatio Thought Blockchain Plugin"
  spec.description   = "Peatio Thought Blockchain Plugin for Rubykube"
  spec.homepage      = "https://thought.live"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/thoughtnetwork/peatio-thought"
    spec.metadata["changelog_uri"] = "https://github.com/thoughtnetwork/peatio-thought/blob/master/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject {|f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 5.2.3", "< 6.1.0"
  spec.add_dependency "better-faraday", "~> 1.0.5"
  spec.add_dependency "faraday", "~> 0.15.4"
  spec.add_dependency "memoist", "~> 0.16.0"
  spec.add_dependency "peatio", ">= 0.6.3"
  spec.add_dependency 'net-http-persistent', '~> 3.0.1'

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "irb"
  spec.add_development_dependency "mocha", "~> 1.8"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop-github"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "webmock", "~> 3.5"
end
