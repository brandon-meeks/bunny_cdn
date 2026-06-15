require "faraday"

module BunnyCdn
  class Client
    DEFAULT_BASE_URL = "https://api.bunny.net"

    attr_reader :api_key, :base_url, :adapter

    def initialize(api_key:, base_url: DEFAULT_BASE_URL, adapter: Faraday.default_adapter)
      @api_key = api_key
      @base_url = base_url
      @adapter = adapter
    end

    def pull_zones
      @pull_zones ||= Resources::PullZones.new(self)
    end

    def storage(zone_name:, region: nil)
      Resources::Storage.new(self, zone_name: zone_name, region: region)
    end

    def connection
      @connection ||= Faraday.new(url: base_url) do |conn|
        conn.headers["AccessKey"] = api_key
        conn.headers["Accept"] = "application/json"
        conn.request :json
        conn.response :json, content_type: /\bjson$/
        conn.request :retry,
          max: 3,
          interval: 1,
          interval_randomness: 0.5,
          backoff_factor: 2,
          exceptions: [Faraday::ServerError, Faraday::TimeoutError, Faraday::ConnectionFailed]
        conn.adapter adapter
      end
    end
  end
end
