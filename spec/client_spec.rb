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
end
