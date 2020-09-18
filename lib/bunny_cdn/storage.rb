module BunnyCdn
  class Storage
    
    RestClient.log = STDOUT # enables RestClient logging

    # Sets the storage zone as set in configuration
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
    
    # Sets the apiKey to that in configuration
    def self.apiKey
      BunnyCdn.configuration.accessKey
    end

    # Sets the necessary headers to make requests to the BunnyCDN API
    def self.headers
      {
        :accesskey => apiKey
      }
    end

    # Gets all the files from the storage zone
    # Params:
    # +path+:: desired path to get files
    def self.getZoneFiles(path= '')
      begin
        response = RestClient.get("#{set_region_url}/#{storageZone}/#{path}", headers)
      rescue RestClient::ExceptionWithResponse => exception
        return exception
      end
      return response.body
    end

    # Gets a single file from the storage zone
    # Params:
    # +path+:: desired path to get file
    # +file+:: specific file to get from storage zone
    def self.getFile(path= '', file)
      begin
        response = RestClient.get("#{set_region_url}/#{storageZone}/#{path}/#{file}", headers)
      rescue RestClient::ExceptionWithResponse => exception
        return exception
      end
      return response.body
    end

    # Uploads a file to the storage zone
    # Params:
    # +path+:: desired path to upload file
    # +file+:: specific file to upload to storage zone
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

    # Deletes a file from the storage zone
    # Params:
    # +path+:: path to delete file from
    # +file+:: specific file to delete from storage zone
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