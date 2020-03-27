require 'spec_helper'

RSpec.describe BunnyCdn::Storage do
  before(:each) do
    BunnyCdn.configure do |config|
      config.storageZone = ENV['STORAGE_ZONE']
      config.accessKey = ENV['ACCESS_KEY']
    end
    headers = {
      :accept => 'application/json',
      :accesskey => BunnyCdn.configuration.accessKey
    }
  end

  describe "#getAllFiles" do
    before do
      stub_request(:get, "https://storage.bunnycdn.com/#{BunnyCdn.configuration.storageZone}/#{ENV['FILE_PATH']}").
        with(
          headers: {
            :accept => 'application/json',
            :accesskey => BunnyCdn.configuration.accessKey
          }).
        to_return(status: 200, body: "")
    end
    it "gets all files from storage zone" do
      headers = {
        :accept => 'application/json',
        :accesskey => BunnyCdn.configuration.accessKey
      }
      BunnyCdn::Storage.getZoneFiles
      expect(WebMock).to have_requested(:get ,"https://storage.bunnycdn.com/#{BunnyCdn.configuration.storageZone}/").
        with(headers: {
          :accept => 'application/json',
          :accesskey => BunnyCdn.configuration.accessKey
        }).once
    end
  end

  describe "#getFile" do
    before do
      stub_request(:get, "https://storage.bunnycdn.com/#{BunnyCdn.configuration.storageZone}/#{ENV['FILE_PATH']}/#{ENV['FILE_NAME']}").
        with(
          headers: {
            :accept => 'application/json',
            :accesskey => BunnyCdn.configuration.accessKey
          }).
        to_return(status: 200)
    end
    it "gets a single file from the storage zone" do
      headers = {
        :accept => 'application/json',
        :accesskey => BunnyCdn.configuration.accessKey
      }
      path = ENV['FILE_PATH']
      file = ENV['FILE_NAME']
      BunnyCdn::Storage.getFile(path, file)
      expect(WebMock).to have_requested(:get ,"https://storage.bunnycdn.com/#{BunnyCdn.configuration.storageZone}/#{path}/#{file}").
        with(headers: {
          :accept => 'application/json',
          :accesskey => BunnyCdn.configuration.accessKey
        }).once
    end
  end

  describe "#uploadFile" do
    before do
      stub_request(:put, "https://storage.bunnycdn.com/#{BunnyCdn.configuration.storageZone}/#{ENV['FILE_PATH']}/#{ENV['FILE_NAME']}").
        with(
          headers: {
            :accesskey => BunnyCdn.configuration.accessKey,
            :checksum => ''
          },
          body: File.read(ENV['FILE_NAME'])).
        to_return(status: 200)
    end
    it "uploads file to storage zone" do
      headers = {
        :accessKey => BunnyCdn.configuration.accessKey,
        :checksum => ''
      }
      path = ENV['FILE_PATH']
      file = ENV['FILE_NAME']
      BunnyCdn::Storage.uploadFile(path, file)
      expect(WebMock).to have_requested(:put ,"https://storage.bunnycdn.com/#{BunnyCdn.configuration.storageZone}/#{ENV['FILE_PATH']}/#{ENV['FILE_NAME']}").
        with(headers: {
          :accesskey => BunnyCdn.configuration.accessKey,
          :checksum => ''
        }).once
    end
  end

  describe "#deleteFile" do
    before do
      stub_request(:delete, "https://storage.bunnycdn.com/#{BunnyCdn.configuration.storageZone}/#{ENV['FILE_PATH']}/#{ENV['FILE_NAME']}").
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
      file = ENV['FILE_NAME']
      BunnyCdn::Storage.deleteFile(path, file)
      expect(WebMock).to have_requested(:delete ,"https://storage.bunnycdn.com/#{BunnyCdn.configuration.storageZone}/#{ENV['FILE_PATH']}/#{ENV['FILE_NAME']}").
        with(headers: {
          :accesskey => BunnyCdn.configuration.accessKey
        }).once
    end
  end
end