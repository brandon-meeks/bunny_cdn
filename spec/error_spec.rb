require "spec_helper"

RSpec.describe BunnyCdn::ApiError do
  it "stores status and response" do
    error = BunnyCdn::ApiError.new("oops", status: 404, response: { "error" => "not found" })

    expect(error.message).to eq("oops")
    expect(error.status).to eq(404)
    expect(error.response).to eq({ "error" => "not found" })
  end
end
