require "spec_helper"

def app
  Bandiera::Server.new
end

describe Bandiera::Server do
  describe "GET on /api/features/:group/:name" do
    it "responds with the correct data" do
      data = {
        group: "pubserv",
        name:  "show_articles_tab",
        desc:  "Show the articles tab",
        type:  "boolean",
        value: true
      }
      feature = Bandiera::Feature.new(data)

      Bandiera::Repository.set(feature)

      get "/api/features/pubserv/show_articles_tab"

      expect(last_response.status).to eq(200)

      expected_response = { "type" => "boolean", "value" => true }

      attributes = JSON.parse(last_response.body)
      expect(attributes).to eq(expected_response)
    end
  end
end

