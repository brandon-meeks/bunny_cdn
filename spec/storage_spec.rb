require 'spec_helper'

RSpec.describe BunnyCdn::Storage do
  before(:each) do
    BunnyCdn.configure do |config|
      config.storageZone = ENV['STORAGE_ZONE']
      config.region = ENV['REGION']
      config.accessKey = ENV['ACCESS_KEY']
    end
    headers = {
      :accesskey => BunnyCdn.configuration.accessKey
    }
  end

  describe "#getAllFiles" do
    before do
      stub_request(:get, "#{BunnyCdn::Storage.set_region_url}/#{BunnyCdn.configuration.storageZone}/#{ENV['FILE_PATH']}").
        with(
          headers: {
            :accesskey => BunnyCdn.configuration.accessKey
          }).
        to_return(status: 200, body: "")
    end
    it "gets all files from storage zone" do
      headers = {
        :accesskey => BunnyCdn.configuration.accessKey
      }
      BunnyCdn::Storage.getZoneFiles
      # RestClient.get("https://storage.bunnycdn.com/#{BunnyCdn.configuration.storageZone}/", headers)
      expect(WebMock).to have_requested(:get ,"#{BunnyCdn::Storage.set_region_url}/#{BunnyCdn.configuration.storageZone}/").
        with(headers: {
          :accesskey => BunnyCdn.configuration.accessKey
        }).once
    end
  end

  describe "#getFile" do
    before do
      file = 'test_file.txt'
      stub_request(:get, "#{BunnyCdn::Storage.set_region_url}/#{BunnyCdn.configuration.storageZone}/#{ENV['FILE_PATH']}/#{file}").
        with(
          headers: {
            :accesskey => BunnyCdn.configuration.accessKey
          }).
        to_return(status: 200)
    end
    it "gets a single file from the storage zone" do
      headers = {
        :accesskey => BunnyCdn.configuration.accessKey
      }
      path = ENV['FILE_PATH']
      file = 'test_file.txt'
      BunnyCdn::Storage.getFile(path, file)
      expect(WebMock).to have_requested(:get ,"#{BunnyCdn::Storage.set_region_url}/#{BunnyCdn.configuration.storageZone}/#{path}/#{file}").
        with(headers: {
          :accesskey => BunnyCdn.configuration.accessKey
        }).once
    end
  end

  describe "#uploadFile" do
    before do
      file = File.join('spec', 'test_file.txt')
      stub_request(:put, "#{BunnyCdn::Storage.set_region_url}/#{BunnyCdn.configuration.storageZone}/#{ENV['FILE_PATH']}/#{File.basename(file)}").
        with(
          headers: {
            :accesskey => BunnyCdn.configuration.accessKey,
            :checksum => ''
          },
          body: File.read(file)).
        to_return(status: 200)
    end
    it "uploads file to storage zone" do
      headers = {
        :accessKey => BunnyCdn.configuration.accessKey,
        :checksum => ''
      }
      path = ENV['FILE_PATH']
      file = File.join('spec', 'test_file.txt')
      # BunnyCdn::Storage.uploadFile(path, file)
      RestClient.put("#{BunnyCdn::Storage.set_region_url}/#{BunnyCdn.configuration.storageZone}/#{ENV['FILE_PATH']}/#{File.basename(file)}", File.read(file), headers)
      expect(WebMock).to have_requested(:put ,"#{BunnyCdn::Storage.set_region_url}/#{BunnyCdn.configuration.storageZone}/#{ENV['FILE_PATH']}/#{File.basename(file)}").
        with(headers: {
          :accesskey => BunnyCdn.configuration.accessKey,
          :checksum => ''
        }).once
    end
  end

  describe "#deleteFile" do
    before do
      file = 'test_file.txt'
      stub_request(:delete, "#{BunnyCdn::Storage.set_region_url}/#{BunnyCdn.configuration.storageZone}/#{ENV['FILE_PATH']}/#{file}").
        with(
          headers: {
            :accesskey => BunnyCdn.configuration.accessKey
          }).
          to_return(status: 200)
    end
    it "deletes file to storage zone" do
      headers = {
        :accessKey => BunnyCdn.configuration.accessKey
      }
      path = ENV['FILE_PATH']
      file = 'test_file.txt'
      BunnyCdn::Storage.deleteFile(path, file)
      expect(WebMock).to have_requested(:delete ,"#{BunnyCdn::Storage.set_region_url}/#{BunnyCdn.configuration.storageZone}/#{ENV['FILE_PATH']}/#{file}").
        with(headers: {
          :accesskey => BunnyCdn.configuration.accessKey
        }).once
    end
  end
end