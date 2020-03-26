require "rest-client"
require "json"
require "bunny_cdn/version"
require_relative "bunny_cdn/configuration"
require_relative "bunny_cdn/storage"

module BunnyCdn
    class << self
        attr_accessor :configuration
    end

    def self.configure
        self.configuration ||= Configuration.new
        yield(configuration)
    end
end