module BunnyCdn
    class Configuration
        attr_accessor :storageZone, :region, :accessKey, :apiKey

        def initialize
            @storageZone = nil
            @region = nil # Options are: eu, ny or sg (Asia)
            @accessKey = nil
            @apiKey = nil
        end
    end

    def self.configuration
        @configuration ||= Configuration.new
    end

    # Set BunnyCdn's configuration
    def self.configuration=(config)
        @configuration = config
    end

    def self.configure
        yield(configuration)
    end
end