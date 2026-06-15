require "spec_helper"

RSpec.describe BunnyCdn::Resources::Base do
  class TestResource < BunnyCdn::Resources::Base
    def test_get(path)
      get(path)
    end

    def test_post(path, body = nil)
      post(path, body)
    end

    def test_delete(path)
      delete(path)
    end

    def test_handle_response(response, path)
      handle_response(response, path)
    end

    def test_parse_body(body)
      parse_body(body)
    end
  end

  let(:connection) { instance_double(Faraday::Connection) }
  let(:client) { instance_double(BunnyCdn::Client, connection: connection) }
  let(:resource) { TestResource.new(client) }

  describe "#parse_body" do
    it "returns nil when body is nil" do
      expect(resource.test_parse_body(nil)).to be_nil
    end

    it "returns empty string when body is empty string" do
      expect(resource.test_parse_body("")).to eq("")
    end

    it "returns parsed JSON hash when body is JSON string" do
      expect(resource.test_parse_body('{"id":1}')).to eq({ "id" => 1 })
    end

    it "returns original string when body is invalid JSON" do
      expect(resource.test_parse_body("{not json}")).to eq("{not json}")
    end

    it "returns original value when body is non-string" do
      expect(resource.test_parse_body(42)).to eq(42)
      expect(resource.test_parse_body({ key: "value" })).to eq({ key: "value" })
    end

    it "returns original string for non-JSON text" do
      expect(resource.test_parse_body("Not Found")).to eq("Not Found")
    end
  end

  describe "#handle_response" do
    it "returns parsed JSON body when response is success" do
      response = instance_double(Faraday::Response, success?: true, body: '{"id":1}')
      expect(resource.test_handle_response(response, "/test")).to eq({ "id" => 1 })
    end

    it "raises ApiError with status and parsed response when response fails" do
      response = instance_double(Faraday::Response, success?: false, status: 404, body: '{"error":"not found"}')
      expect {
        resource.test_handle_response(response, "/test")
      }.to raise_error(BunnyCdn::ApiError) do |error|
        expect(error.status).to eq(404)
        expect(error.response).to eq({ "error" => "not found" })
      end
    end

    it "uses raw string for ApiError response when error body is non-JSON" do
      response = instance_double(Faraday::Response, success?: false, status: 500, body: "internal server error")
      expect {
        resource.test_handle_response(response, "/test")
      }.to raise_error(BunnyCdn::ApiError) do |error|
        expect(error.status).to eq(500)
        expect(error.response).to eq("internal server error")
      end
    end
  end

  describe "HTTP verb delegation" do
    let(:success_response) { instance_double(Faraday::Response, success?: true, body: '{"ok":true}') }

    describe "#get" do
      it "delegates to connection.get(path)" do
        expect(connection).to receive(:get).with("/test", {}).and_return(success_response)
        resource.test_get("/test")
      end
    end

    describe "#post" do
      it "delegates to connection.post(path, body)" do
        expect(connection).to receive(:post).with("/test", { foo: "bar" }).and_return(success_response)
        resource.test_post("/test", { foo: "bar" })
      end
    end

    describe "#delete" do
      it "delegates to connection.delete(path)" do
        expect(connection).to receive(:delete).with("/test").and_return(success_response)
        resource.test_delete("/test")
      end
    end
  end
end
