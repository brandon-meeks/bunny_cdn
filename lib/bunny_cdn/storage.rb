module BunnyCdn
  class Storage
    
    RestClient.log = STDOUT # enables RestClient logging

    BASE_URL = 'https://storage.bunnycdn.com'

    def self.storageZone
      BunnyCdn.configuration.storageZone
    end

    def self.apiKey
      BunnyCdn.configuration.accessKey
    end

    def self.headers
      {
        :accesskey => apiKey
      }
    end

    def self.getZoneFiles(path= '')
      begin
        response = RestClient.get("#{BASE_URL}/#{storageZone}/#{path}", headers)
      rescue RestClient::ExceptionWithResponse => exception
        return exception
      end
      return response.body
    end

    def self.getFile(path= '', file)
      begin
        response = RestClient.get("#{BASE_URL}/#{storageZone}/#{path}/#{file}", headers)
      rescue RestClient::ExceptionWithResponse => exception
        return exception
      end
      return response.body
    end

    def self.uploadFile(path= '', file)
      fileName = File.basename(file)
      headers = {
        :accessKey => apiKey,
        :checksum => ''
      }
      begin
        response = RestClient.put("#{BASE_URL}/#{storageZone}/#{path}/#{fileName}", File.read(file), headers)
      rescue RestClient::ExceptionWithResponse => exception
        return exception
      end
      return response.body
    end

    def self.deleteFile(path= '', file)
      begin
        response = RestClient.delete("#{BASE_URL}/#{storageZone}/#{path}/#{file}", headers)
      rescue RestClient::ExceptionWithResponse => exception
        return exception
      end
      return response.body
    end

  end
end