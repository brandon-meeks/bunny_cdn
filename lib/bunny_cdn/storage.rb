module BunnyCdn
  class Storage

    BASE_URL = 'https://storage.bunnycdn.com'
    STORAGE_ZONE = 'meekstech' # BunnyCdn.configuration.storageZone
    API_KEY = '9be063cc-ab99-453c-8aa062ca040e-d1c8-4cc4' # BunnyCdn.configuration.accessKey

    HEADERS =
      {
        :accept => 'application/json',
        :accesskey => API_KEY
      }

    def self.getZoneFiles(path= '')
      response = RestClient.get("#{BASE_URL}/#{STORAGE_ZONE}/#{path}", HEADERS)
      puts response
      return response.body
    end

    def self.getFile(path= '', file)
      response = RestClient.get("#{BASE_URL}/#{STORAGE_ZONE}/#{path}/#{file}", HEADERS)
      return response.body
    end

    def self.uploadFile(path= '', file)
      fileName = File.basename(file)
      headers = {
        :accessKey => API_KEY,
        :checksum => ''
      }
      response = RestClient.put("#{BASE_URL}/#{STORAGE_ZONE}/#{path}/#{fileName}", File.read(file), headers)
      return response.body
    end

    def self.deleteFile(path= '', file)
      headers = {
        :accessKey => API_KEY
      }
      response = RestClient.delete("#{BASE_URL}/#{STORAGE_ZONE}/#{path}/#{file}", headers)
      return response.body
    end

  end
end