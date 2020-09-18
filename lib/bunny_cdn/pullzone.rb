module BunnyCdn
  class Pullzone

    RestClient.log = STDOUT # enables RestClient logging

    BASE_URL = 'https://bunnycdn.com/api/pullzone' # URL to for BunnyCDN's Pullzone API

    # Sets the apiKey to that in configuration
    def self.apiKey
      @apiKey = BunnyCdn.configuration.apiKey
    end

    # Sets the necessary headers to make requests to the BunnyCDN API
    def self.headers
      {
        :accesskey => apiKey,
        :accept => 'application/json',
        :content_type => 'application/json'
      }
    end

    # Gets all Pull Zones from BunnyCDN
    def self.getAllPullzones
      begin
        response = RestClient.get(BASE_URL, headers)
      rescue RestClient::ExceptionWithResponse => exception
        return exception
      end
      return response
    end

    # Creates a new pullzone
    # Params:
    # +name+:: the name of the new Pull Zone
    # +type+:: the pricing type of the pull zone you wish to add. 0 = Standard, 1 = High Volume
    # originURL+:: the origin URL where the pull zone files are pulled from.
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

    # Gets the details of the pull zone using the given ID
    # Params:
    # +id+:: the ID of the Pull Zone to return
    def self.getSinglePullzone(id)
      begin
        response = RestClient.get("#{BASE_URL}/#{id}", headers)
      rescue RestClient::ExceptionWithResponse => exception
        return exception
      end
      return response
    end

    # Deletes the pull zone using the given ID
    # Params:
    # +id+:: the ID of the Pull Zone to delete
    def self.deletePullzone(id)
      begin
        response = RestClient.delete("#{BASE_URL}/#{id}", headers)
      rescue RestClient::ExceptionWithResponse => exception
        return exception
      end
      return response
    end

    # Purges the cache for the Pull Zone using the given ID
    # Params:
    # +id+:: the ID of the zone which should have the cache purged
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