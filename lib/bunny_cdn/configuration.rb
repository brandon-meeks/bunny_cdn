module BunnyCdn
    class Configuration
        attr_accessor :storageZone, :region, :accessKey, :apiKey

        # Sets the configuration variables upon calling BunnyCdn::Configuration.new
        def initialize
            @storageZone = nil
            @region = nil # Options are: eu, ny, la or sg (Asia)
            @accessKey = nil
            @apiKey = nil
        end
    end

    def self.configuration
        @configuration ||= Configuration.new
    end

    def self.configuration=(config)
        @configuration = config
    end

    def self.configure
        yield(configuration)
    end
end