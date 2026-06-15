require "spec_helper"

RSpec.describe BunnyCdn::Resources::PullZones do
  let(:client) { BunnyCdn::Client.new(api_key: "test-key") }
  let(:resource) { described_class.new(client) }

  describe "#list" do
    before do
      stub_request(:get, "https://api.bunny.net/pullzone?page=1&perPage=1000")
        .with(headers: { "AccessKey" => "test-key", "Accept" => "application/json" })
        .to_return(status: 200, body: [{ "Id" => 1 }].to_json, headers: { "Content-Type" => "application/json" })
    end

    it "returns parsed JSON" do
      result = resource.list
      expect(result).to eq([{ "Id" => 1 }])
    end

    it "sends default query params" do
      resource.list
      expect(WebMock).to have_requested(:get, "https://api.bunny.net/pullzone?page=1&perPage=1000")
        .with(headers: { "AccessKey" => "test-key", "Accept" => "application/json" })
    end

    it "sends custom page and per_page query params" do
      stub_request(:get, "https://api.bunny.net/pullzone?page=2&perPage=50")
        .with(headers: { "AccessKey" => "test-key", "Accept" => "application/json" })
        .to_return(status: 200, body: [{ "Id" => 2 }].to_json, headers: { "Content-Type" => "application/json" })

      resource.list(page: 2, per_page: 50)
      expect(WebMock).to have_requested(:get, "https://api.bunny.net/pullzone?page=2&perPage=50")
        .with(headers: { "AccessKey" => "test-key", "Accept" => "application/json" })
    end
  end

  describe "#find" do
    before do
      stub_request(:get, "https://api.bunny.net/pullzone/12345")
        .with(headers: { "AccessKey" => "test-key", "Accept" => "application/json" })
        .to_return(status: 200, body: { "Id" => 12345 }.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "returns the pull zone" do
      result = resource.find(12345)
      expect(result).to eq({ "Id" => 12345 })
    end
  end

  describe "#create" do
    before do
      stub_request(:post, "https://api.bunny.net/pullzone")
        .with(
          headers: { "AccessKey" => "test-key", "Accept" => "application/json", "Content-Type" => "application/json" },
          body: { name: "test", type: 0, originUrl: "http://example.com" }.to_json
        )
        .to_return(status: 200, body: { "Id" => 1 }.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "creates a pull zone" do
      result = resource.create(name: "test", type: 0, origin_url: "http://example.com")
      expect(result).to eq({ "Id" => 1 })
    end
  end

  describe "#delete" do
    before do
      stub_request(:delete, "https://api.bunny.net/pullzone/12345")
        .with(headers: { "AccessKey" => "test-key", "Accept" => "application/json" })
        .to_return(status: 200, body: "", headers: { "Content-Type" => "application/json" })
    end

    it "deletes the pull zone" do
      result = resource.delete(12345)
      expect(result).to eq("")
    end
  end

  describe "#purge" do
    before do
      stub_request(:post, "https://api.bunny.net/pullzone/12345/purgeCache")
        .with(headers: { "AccessKey" => "test-key", "Accept" => "application/json" })
        .to_return(status: 200, body: "", headers: { "Content-Type" => "application/json" })
    end

    it "purges cache" do
      result = resource.purge(12345)
      expect(result).to eq("")
    end
  end

  describe "#add_hostname" do
    context "when hostname is not registered" do
      before do
        stub_request(:post, "https://api.bunny.net/pullzone/12345/addHostname")
          .with(
            headers: { "AccessKey" => "test-key", "Accept" => "application/json", "Content-Type" => "application/json" },
            body: { "Hostname" => "cdn.example.com" }.to_json
          )
          .to_return(status: 200, body: { "Hostname" => "cdn.example.com" }.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "adds the hostname" do
        result = resource.add_hostname(12345, "cdn.example.com")
        expect(result).to eq({ "Hostname" => "cdn.example.com" })
      end
    end

    context "when hostname is already registered" do
      before do
        stub_request(:post, "https://api.bunny.net/pullzone/12345/addHostname")
          .with(
            headers: { "AccessKey" => "test-key", "Accept" => "application/json", "Content-Type" => "application/json" },
            body: { "Hostname" => "cdn.example.com" }.to_json
          )
          .to_return(
            status: 400,
            body: { "ErrorKey" => "pullzone.hostname_already_registered" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns success with skipped flag" do
        result = resource.add_hostname(12345, "cdn.example.com")
        expect(result).to eq({ "success" => true, "skipped" => true })
      end
    end

    context "when other errors occur" do
      before do
        stub_request(:post, "https://api.bunny.net/pullzone/12345/addHostname")
          .to_return(status: 500, body: "internal error", headers: { "Content-Type" => "text/plain" })
      end

      it "raises ApiError" do
        expect { resource.add_hostname(12345, "cdn.example.com") }.to raise_error(BunnyCdn::ApiError)
      end
    end
  end

  describe "#load_free_ssl" do
    before do
      stub_request(:get, "https://api.bunny.net/pullzone/loadFreeCertificate?hostname=cdn.example.com")
        .with(headers: { "AccessKey" => "test-key", "Accept" => "application/json" })
        .to_return(status: 200, body: { "Success" => true }.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "loads free SSL certificate" do
      result = resource.load_free_ssl(hostname: "cdn.example.com")
      expect(result).to eq({ "Success" => true })
    end
  end

  describe "#purge_by_tag" do
    before do
      stub_request(:post, "https://api.bunny.net/pullzone/12345/purgeCache?cacheTag=my-tag")
        .with(headers: { "AccessKey" => "test-key", "Accept" => "application/json" })
        .to_return(status: 200, body: "", headers: { "Content-Type" => "application/json" })
    end

    it "purges cache by tag" do
      result = resource.purge_by_tag(12345, "my-tag")
      expect(result).to eq("")
    end
  end

  describe "#health_check" do
    context "when API is healthy" do
      before do
        stub_request(:get, "https://api.bunny.net/pullzone?page=1&perPage=1")
          .with(headers: { "AccessKey" => "test-key", "Accept" => "application/json" })
          .to_return(status: 200, body: [{ "Id" => 1 }].to_json, headers: { "Content-Type" => "application/json" })
      end

      it "returns true" do
        expect(resource.health_check).to be true
      end
    end

    context "when API is unhealthy" do
      before do
        stub_request(:get, "https://api.bunny.net/pullzone?page=1&perPage=1")
          .to_return(status: 500, body: "error", headers: { "Content-Type" => "text/plain" })
      end

      it "returns false" do
        expect(resource.health_check).to be false
      end
    end
  end

  describe "error handling" do
    before do
      stub_request(:get, "https://api.bunny.net/pullzone/99999")
        .to_return(status: 404, body: { "error" => "not found" }.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "raises ApiError with status and response" do
      expect { resource.find(99999) }.to raise_error(BunnyCdn::ApiError) do |error|
        expect(error.status).to eq(404)
        expect(error.response).to eq({ "error" => "not found" })
      end
    end
  end
end
