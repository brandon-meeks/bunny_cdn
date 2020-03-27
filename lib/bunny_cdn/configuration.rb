module BunnyCdn
    class Configuration
        attr_accessor :storageZone, :accessKey

        def initialize
            @storageZone = nil
            @accessKey = nil
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