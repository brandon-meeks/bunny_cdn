module BunnyCdn
  class Storage

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
      response = RestClient.get("#{BASE_URL}/#{storageZone}/#{path}", headers)
      return response.body
    end

    def self.getFile(path= '', file)
      response = RestClient.get("#{BASE_URL}/#{storageZone}/#{path}/#{file}", headers)
      return response.body
    end

    def self.uploadFile(path= '', file)
      fileName = File.basename(file)
      headers = {
        :accessKey => apiKey,
        :checksum => ''
      }
      response = RestClient.put("#{BASE_URL}/#{storageZone}/#{path}/#{fileName}", File.read(file), headers)
      return response.body
    end

    def self.deleteFile(path= '', file)
      response = RestClient.delete("#{BASE_URL}/#{storageZone}/#{path}/#{file}", headers)
      return response.body
    end

  end
end