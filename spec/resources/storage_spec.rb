require "spec_helper"
require "tempfile"

RSpec.describe BunnyCdn::Resources::Storage do
  let(:client) { BunnyCdn::Client.new(api_key: "test-key") }
  let(:resource) { described_class.new(client, zone_name: "test-zone", region: "de") }

  describe "#list" do
    before do
      stub_request(:get, "https://storage.bunnycdn.com/test-zone/images/")
        .with(headers: { "AccessKey" => "test-key" })
        .to_return(status: 200, body: [{ "ObjectName" => "file.txt" }].to_json, headers: { "Content-Type" => "application/json" })
    end

    it "lists files in a path" do
      result = resource.list(path: "images")
      expect(result).to eq([{ "ObjectName" => "file.txt" }])
    end

    it "appends trailing slash if missing" do
      stub_request(:get, "https://storage.bunnycdn.com/test-zone/docs/")
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

      resource.list(path: "docs")
      expect(WebMock).to have_requested(:get, "https://storage.bunnycdn.com/test-zone/docs/")
    end
  end

  describe "#list with default region" do
    let(:default_resource) { described_class.new(client, zone_name: "test-zone") }

    before do
      stub_request(:get, "https://storage.bunnycdn.com/test-zone/")
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })
    end

    it "uses default de region" do
      default_resource.list
      expect(WebMock).to have_requested(:get, "https://storage.bunnycdn.com/test-zone/")
    end
  end

  describe "#list with ny region" do
    let(:ny_resource) { described_class.new(client, zone_name: "test-zone", region: "ny") }

    before do
      stub_request(:get, "https://ny.storage.bunnycdn.com/test-zone/")
        .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })
    end

    it "uses ny region subdomain" do
      ny_resource.list
      expect(WebMock).to have_requested(:get, "https://ny.storage.bunnycdn.com/test-zone/")
    end
  end

  describe "#get" do
    before do
      stub_request(:get, "https://storage.bunnycdn.com/test-zone/images/logo.png")
        .with(headers: { "AccessKey" => "test-key" })
        .to_return(status: 200, body: "binary-data", headers: { "Content-Type" => "application/octet-stream" })
    end

    it "returns raw file body" do
      result = resource.get("images/logo.png")
      expect(result).to eq("binary-data")
    end
  end

  describe "#upload with file path" do
    let(:tempfile) { Tempfile.new(["logo", ".png"]) }

    before do
      stub_request(:put, "https://storage.bunnycdn.com/test-zone/images/logo.png")
        .with(
          headers: { "AccessKey" => "test-key" },
          body: "file contents"
        )
        .to_return(status: 200, body: "", headers: { "Content-Type" => "application/json" })

      tempfile.write("file contents")
      tempfile.rewind
    end

    after { tempfile.close; tempfile.unlink }

    it "uploads file from path" do
      resource.upload("images/logo.png", tempfile.path)
      expect(WebMock).to have_requested(:put, "https://storage.bunnycdn.com/test-zone/images/logo.png")
    end
  end

  describe "#upload with uploaded file object" do
    let(:uploaded_file) { double("UploadedFile", original_filename: "logo.png", tempfile: StringIO.new("file contents")) }

    before do
      stub_request(:put, "https://storage.bunnycdn.com/test-zone/images/logo.png")
        .with(
          headers: { "AccessKey" => "test-key" },
          body: "file contents"
        )
        .to_return(status: 200, body: "", headers: { "Content-Type" => "application/json" })
    end

    it "uploads from uploaded file object" do
      resource.upload("images/logo.png", uploaded_file)
      expect(WebMock).to have_requested(:put, "https://storage.bunnycdn.com/test-zone/images/logo.png")
    end
  end

  describe "#delete" do
    before do
      stub_request(:delete, "https://storage.bunnycdn.com/test-zone/images/logo.png")
        .with(headers: { "AccessKey" => "test-key" })
        .to_return(status: 200, body: "", headers: { "Content-Type" => "application/json" })
    end

    it "deletes the file" do
      result = resource.delete("images/logo.png")
      expect(result).to eq("")
    end
  end

  describe "error handling" do
    before do
      stub_request(:get, "https://storage.bunnycdn.com/test-zone/missing.png")
        .to_return(status: 404, body: { "error" => "not found" }.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "raises ApiError with status and response" do
      expect { resource.get("missing.png") }.to raise_error(BunnyCdn::ApiError) do |error|
        expect(error.status).to eq(404)
        expect(error.response).to eq({ "error" => "not found" })
      end
    end
  end
end
