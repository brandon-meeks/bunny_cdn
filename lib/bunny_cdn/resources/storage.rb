module BunnyCdn
  module Resources
    class Storage < Base
      attr_reader :zone_name, :region

      def initialize(client, zone_name:, region: nil)
        super(client)
        @zone_name = zone_name
        @region = region
      end

      def list(path: "")
        get(normalize_path(path))
      end

      def get(remote_path)
        super("#{zone_name}/#{remote_path}")
      end

      def upload(remote_path, file)
        contents = extract_file_data(file)
        put_request("#{zone_name}/#{remote_path}", contents)
      end

      def delete(remote_path)
        super("#{zone_name}/#{remote_path}")
      end

      private

      def connection
        @storage_connection ||= Faraday.new(url: storage_base_url) do |conn|
          conn.headers["AccessKey"] = client.api_key
          conn.request :json
          conn.adapter Faraday.default_adapter
        end
      end

      def storage_base_url
        if region.nil? || region == "de"
          "https://storage.bunnycdn.com"
        else
          "https://#{region}.storage.bunnycdn.com"
        end
      end

      def normalize_path(path)
        path = path.to_s
        path.end_with?("/") || path.empty? ? path : "#{path}/"
      end

      def extract_file_data(file)
        if file.respond_to?(:original_filename) && file.respond_to?(:tempfile)
          file.tempfile.read
        else
          File.read(file)
        end
      end

      def put_request(path, body)
        response = connection.put(path, body)
        handle_response(response, path)
      end
    end
  end
end
