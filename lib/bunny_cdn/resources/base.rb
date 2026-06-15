module BunnyCdn
  module Resources
    class Base
      attr_reader :client

      def initialize(client)
        @client = client
      end

      protected

      def connection
        client.connection
      end

      private

      def get(path, params = {})
        response = connection.get(path, params)
        handle_response(response, path)
      end

      def post(path, body = {})
        response = connection.post(path, body)
        handle_response(response, path)
      end

      def delete(path)
        response = connection.delete(path)
        handle_response(response, path)
      end

      def handle_response(response, path)
        if response.success?
          parse_body(response.body)
        else
          raise ApiError.new(
            "[BunnyCdn] #{path} failed: #{response.status} #{response.body}",
            status: response.status,
            response: parse_body(response.body)
          )
        end
      end

      def parse_body(body)
        return body unless body.is_a?(String)

        if body.empty?
          ""
        else
          JSON.parse(body)
        end
      rescue JSON::ParserError
        body
      end
    end
  end
end
