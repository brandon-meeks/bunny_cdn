module BunnyCdn
  class Pullzone

    BASE_URL = 'https://bunnycdn.com/api/pullzone'

    def self.apiKey
      @apiKey = BunnyCdn.configuration.apiKey
    end

    def self.headers
      {
        :accesskey => apiKey,
        :accept => 'application/json',
        :content_type => 'application/json'
      }
    end

    def self.getAllPullzones
      begin
        response = RestClient.get(BASE_URL, headers)
      rescue RestClient::ExceptionWithResponse => exception
        return exception
      end
      return response
    end

    def self.createPullzone(name, type = 0, originUrl)
      values = {
        :name => name,
        :type => type,
        :originUrl => originUrl
      }
      begin
        response = RestClient.post(BASE_URL, values.to_json, headers)
      rescue RestClient::ExceptionWithResponse => exception
        return exception
      end
      return response
    end

    def self.getSinglePullzone(id)
      begin
        response = RestClient.get("#{BASE_URL}/#{id}", headers)
      rescue RestClient::ExceptionWithResponse => exception
        return exception
      end
      return response
    end

    def self.deletePullzone(id)
      begin
        response = RestClient.delete("#{BASE_URL}/#{id}", headers)
      rescue RestClient::ExceptionWithResponse => exception
        return exception
      end
      return response
    end

    def self.purgeCache(id)
      begin
        response = RestClient.post("#{BASE_URL}/#{id}/purgeCache", {}.to_json, headers)
      rescue RestClient::ExceptionWithResponse => exception
        return exception
      end
      return response
    end
  end
end