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
          response.body
        else
          raise ApiError.new(
            "[BunnyCdn] #{path} failed: #{response.status} #{response.body}",
            status: response.status,
            response: response.body
          )
        end
      end
    end
  end
end
