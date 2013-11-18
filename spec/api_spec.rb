require "spec_helper"

def app
  Server.new
end

describe Server do

  before :each do
    Ohm.flush
  end

  describe "GET on /api/features/:group/:name" do
    it "responds with the correct data" do
      group = Group.create(name: 'pubserv')

      data = {
        group: group,
        name:  "show_articles_tab",
        description:  "Show the articles tab",
        type:  "boolean",
        value: true
      }

      feature = Feature.create(data)

      get "/api/features/pubserv/show_articles_tab"

      expect(last_response.status).to eq(200)

      expected_response = { "type" => "boolean", "value" => "true" }

      attributes = JSON.parse(last_response.body)
      expect(attributes).to eq(expected_response)
    end
  end
end
