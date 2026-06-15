require "cgi"

module BunnyCdn
  module Resources
    class PullZones < Base
      def list(page: 1, per_page: 1000)
        get("pullzone?page=#{page}&perPage=#{per_page}")
      end

      def find(id)
        get("pullzone/#{id.to_i}")
      end

      def create(name:, type:, origin_url:)
        post("pullzone", {
          name: name,
          type: type,
          originUrl: origin_url
        })
      end

      def delete(id)
        path = "pullzone/#{id.to_i}"
        response = connection.delete(path)
        handle_response(response, path)
      end

      def purge(id)
        post("pullzone/#{id.to_i}/purgeCache")
      end

      def add_hostname(id, hostname)
        post("pullzone/#{id.to_i}/addHostname", {
          "Hostname" => hostname
        })
      rescue ApiError => e
        if hostname_already_registered?(e)
          { "success" => true, "skipped" => true }
        else
          raise
        end
      end

      def load_free_ssl(hostname:)
        get("pullzone/loadFreeCertificate", { hostname: hostname })
      end

      def purge_by_tag(id, tag)
        post("pullzone/#{id.to_i}/purgeCache?cacheTag=#{CGI.escape(tag)}", {})
      end

      def health_check
        get("pullzone", { page: 1, perPage: 1 })
        true
      rescue ApiError
        false
      end

      private

      def hostname_already_registered?(error)
        return false unless error.status == 400
        return false unless error.response.is_a?(Hash)

        error.response["ErrorKey"] == "pullzone.hostname_already_registered"
      end
    end
  end
end
