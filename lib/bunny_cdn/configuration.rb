module BunnyCdn
    class Configuration
        attr_accessor :storageZone, :accessKey

        def initialize
            @storageZone = nil
            @accessKey = nil
        end
    end
end