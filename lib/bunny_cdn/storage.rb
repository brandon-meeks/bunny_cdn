module BunnyCdn
  class Storage
    
    RestClient.log = STDOUT # enables RestClient logging

    def self.storageZone
      BunnyCdn.configuration.storageZone
    end
    # Sets the proper URL based on the region set in configuration
    def self.set_region_url
      case BunnyCdn.configuration.region
      when nil || 'eu'
        'https://storage.bunnycdn.com'
      when 'ny'
        'https://ny.storage.bunnycdn.com'
      when 'la'
        'https://la.storage.bunnycdn.com'
      when 'sg'
        'https://sg.storage.bunnycdn.com'
      end
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
        response = RestClient.get("#{set_region_url}/#{storageZone}/#{path}", headers)
      rescue RestClient::ExceptionWithResponse => exception
        return exception
      end
      return response.body
    end

    def self.getFile(path= '', file)
      begin
        response = RestClient.get("#{set_region_url}/#{storageZone}/#{path}/#{file}", headers)
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
        response = RestClient.put("#{set_region_url}/#{storageZone}/#{path}/#{fileName}", File.read(file), headers)
      rescue RestClient::ExceptionWithResponse => exception
        return exception
      end
      return response.body
    end

    def self.deleteFile(path= '', file)
      begin
        response = RestClient.delete("#{set_region_url}/#{storageZone}/#{path}/#{file}", headers)
      rescue RestClient::ExceptionWithResponse => exception
        return exception
      end
      return response.body
    end

  end
end