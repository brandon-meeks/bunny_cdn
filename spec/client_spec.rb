require "spec_helper"

RSpec.describe BunnyCdn::Client do
  let(:client) { described_class.new(api_key: "test-key") }

  describe "#initialize" do
    it "accepts an api_key" do
      expect(client.instance_variable_get(:@api_key)).to eq("test-key")
    end

    it "defaults base_url to https://api.bunny.net" do
      expect(client.instance_variable_get(:@base_url)).to eq("https://api.bunny.net")
    end

    it "allows custom base_url" do
      custom = described_class.new(api_key: "key", base_url: "https://custom.bunny.net")
      expect(custom.instance_variable_get(:@base_url)).to eq("https://custom.bunny.net")
    end

    it "allows custom adapter" do
      adapter = Faraday::Adapter::Test
      custom = described_class.new(api_key: "key", adapter: adapter)
      expect(custom.instance_variable_get(:@adapter)).to eq(adapter)
    end
  end

  describe "#pull_zones" do
    it "returns a PullZones resource" do
      expect(client.pull_zones).to be_a(BunnyCdn::Resources::PullZones)
    end

    it "memoizes the resource" do
      first = client.pull_zones
      expect(client.pull_zones).to equal(first)
    end
  end

  describe "#storage" do
    it "returns a Storage resource" do
      storage = client.storage(zone_name: "my-zone")
      expect(storage).to be_a(BunnyCdn::Resources::Storage)
    end
  end

  describe "#connection" do
    describe "headers" do
      it "sets AccessKey header" do
        stub_request(:get, "https://api.bunny.net/test").to_return(status: 200, body: "{}")
        client.connection.get("/test")
        expect(WebMock).to have_requested(:get, "https://api.bunny.net/test")
          .with(headers: {"AccessKey" => "test-key"})
      end

      it "sets Accept header to application/json" do
        stub_request(:get, "https://api.bunny.net/test").to_return(status: 200, body: "{}")
        client.connection.get("/test")
        expect(WebMock).to have_requested(:get, "https://api.bunny.net/test")
          .with(headers: {"Accept" => "application/json"})
      end
    end

    describe "JSON encoding" do
      it "encodes request bodies as JSON" do
        stub_request(:post, "https://api.bunny.net/test").to_return(status: 200, body: "{}")
        client.connection.post("/test") { |req| req.body = {name: "test"} }
        expect(WebMock).to have_requested(:post, "https://api.bunny.net/test")
          .with(body: '{"name":"test"}')
      end
    end

    describe "retry middleware" do
      it "is configured in the middleware stack" do
        handlers = client.connection.builder.handlers.map(&:name)
        expect(handlers).to include("Faraday::Retry::Middleware")
      end

      it "retries on timeout errors" do
        stub_request(:get, "https://api.bunny.net/test")
          .to_raise(Faraday::TimeoutError).then
          .to_return(status: 200, body: '{"ok":true}')

        response = client.connection.get("/test")
        expect(JSON.parse(response.body)["ok"]).to be true
      end
    end
  end
end
