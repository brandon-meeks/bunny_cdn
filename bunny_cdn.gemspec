lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bunny_cdn/version"

Gem::Specification.new do |spec|
  spec.name          = "bunny_cdn"
  spec.version       = BunnyCdn::VERSION
  spec.authors       = "Brandon Meeks"
  spec.email         = "meeksb86@gmail.com"

  spec.summary       = %q{Gem to work with BunnyCDN}
  spec.description   = %q{This is a simple gem to help you work with BunnyCDN.}
  spec.homepage      = "https://github.com/brandon-meeks/bunny_cdn_gem"
  spec.license       = "MIT"

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/brandon-meeks/bunny_cdn_gem"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'rest-client', '~> 2.1'
  spec.add_dependency 'json', '~> 2.3'

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", '~> 3.8', '>= 3.8.3'

  spec.required_ruby_version = '>= 2.0.1'
end
