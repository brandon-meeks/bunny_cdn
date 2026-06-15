lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bunny_cdn/version"

Gem::Specification.new do |spec|
  spec.name          = "bunny_cdn"
  spec.version       = BunnyCdn::VERSION
  spec.authors       = "Brandon Meeks"
  spec.email         = "meeksb86@gmail.com"

  spec.summary       = %q{Modern Ruby client for Bunny.net CDN API}
  spec.description   = %q{Instance-based Faraday client for Bunny.net Storage and Pullzone APIs.}
  spec.homepage      = "https://github.com/brandon-meeks/bunny_cdn_gem"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/brandon-meeks/bunny_cdn_gem"
  spec.metadata["changelog_uri"] = "https://github.com/brandon-meeks/bunny_cdn/releases"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", ">= 2.0", "< 3"
  spec.add_dependency "faraday-retry", ">= 2.0", "< 3"
  spec.add_dependency "json", "~> 2.12"

  spec.add_development_dependency "bundler", "~> 2.6"
  spec.add_development_dependency "rake", "~> 13.2", ">= 13.2.1"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "webmock", "~> 3.25", ">= 3.25.1"

  spec.required_ruby_version = ">= 3.1.0"
end
