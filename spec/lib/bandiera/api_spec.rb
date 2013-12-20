require "spec_helper"
require "rack/test"

describe Bandiera::API do
  include Rack::Test::Methods

  def app
    Bandiera::API
  end

  before do
    service = Bandiera::FeatureService.new
    service.add_features([
      { group: "pubserv",   name: "show_subjects",  description: "Show all subject related features", enabled: false },
      { group: "pubserv",   name: "show_search",    description: "Show the search bar",               enabled: true  },
      { group: "pubserv",   name: "xmas_mode",      description: "Xmas mode: SNOWFLAKES!",            enabled: false },
      { group: "laserwolf", name: "enable_caching", description: "Enable caching",                    enabled: false },
      { group: "shunter",   name: "stats_logging",  description: "Log stats",                         enabled: true  }
    ])
  end

  describe "GET /v1/groups" do
    it "returns an array of group names" do
      get "/v1/groups"
      expect(last_response.status).to eq(200)

      expected_data = {
        "groups" => [
          { "name" => "laserwolf" },
          { "name" => "pubserv" },
          { "name" => "shunter" }
        ]
      }

      data = JSON.parse(last_response.body)
      expect(data).to eq(expected_data)
    end
  end

  describe "POST /v1/groups" do
    context "with valid params" do
      it "creates a new group" do
        post "/v1/groups", group: { name: "wibble" }
        expect(last_response.status).to eq(201)

        expected_data = { "group" => { "name" => "wibble" } }

        data = JSON.parse(last_response.body)
        expect(data).to eq(expected_data)
      end
    end

    context "with invalid params" do
      it "returns an error" do
        post "/v1/groups", params: { wee: "woo" }
        expect(last_response.status).to eq(400)

        expected_data = { "error" => "Invalid parameters, required params are { 'group' => { 'name' => 'YOUR GROUP NAME' }  }" }

        data = JSON.parse(last_response.body)
        expect(data).to eq(expected_data)
      end
    end
  end

  describe "GET /v1/groups/:group_name/features" do
    context "when the group exists" do
      it "returns an array of features for the group" do
        get "/v1/groups/shunter/features"

        expect(last_response.status).to eq(200)

        data = JSON.parse(last_response.body)
        expect(data).to be_an_instance_of(Hash)
        expect(data["features"]).to be_an_instance_of(Array)
        expect(data["features"].size).to be(1)
        expect(data["features"].first).to eq({
          "group"       => "shunter",
          "name"        => "stats_logging",
          "description" => "Log stats",
          "enabled"     => true
        })
      end
    end

    context "when the group doesn't exist" do
      it "returns a 404" do
        get "/v1/groups/non_existent/features"
        expect(last_response.status).to eq(404)

        data = JSON.parse(last_response.body)
        expect(data).to be_an_instance_of(Hash)
        expect(data["error"]).to eq("Cannot find group 'non_existent'")
      end
    end
  end

  describe "POST /v1/groups/:group_name/features" do
    context "when the group exists" do
      context "with valid params" do
        it "creates a new feature for the group" do
          feature_params = {
            "name"        => "new_feature",
            "description" => "A new new feature",
            "enabled"     => true
          }

          post "/v1/groups/shunter/features", { feature: feature_params }
          expect(last_response.status).to eq(201)

          expected_data = { "feature" => feature_params.merge({ "group" => "shunter" }) }

          data = JSON.parse(last_response.body)
          expect(data).to eq(expected_data)
        end
      end

      context "with invalid params" do
        it "returns an error" do
          feature_params = {
            "feature_name" => "new_feature",
            "enabled"      => true
          }

          post "/v1/groups/shunter/features", { feature: feature_params }
          expect(last_response.status).to eq(400)

          expected_data = { "error" => "Invalid parameters, required params are { 'feature' => { 'name' => 'FEATURE NAME', 'description' => 'FEATURE DESCRIPTION', 'enabled' => 'TRUE OR FALSE' }  }" }

          data = JSON.parse(last_response.body)
          expect(data).to eq(expected_data)
        end
      end
    end

    context "when the group doesn't exist" do
      it "creates the group and the new feature" do
        feature_params = {
          "name"        => "test-feature",
          "description" => "A NEW TEST FEATURE",
          "enabled"     => false
        }

        post "/v1/groups/wibble/features", { feature: feature_params }
        expect(last_response.status).to eq(201)

        expected_data = { "feature" => feature_params.merge({ "group" => "wibble" }) }

        data = JSON.parse(last_response.body)
        expect(data).to eq(expected_data)
      end
    end
  end

  describe "GET /v1/groups/:group_name/features/:feature_name" do
    context "when both the group and the feature exists" do
      it "returns the feature" do
        get "/v1/groups/pubserv/features/show_search"

        expect(last_response.status).to eq(200)

        data = JSON.parse(last_response.body)
        expect(data).to be_an_instance_of(Hash)
        expect(data.keys).to include("feature")
        expect(data["feature"]).to eq({
          "group"       => "pubserv",
          "name"        => "show_search",
          "description" => "Show the search bar",
          "enabled"     => true
        })
      end
    end

    context "when the group doesn't exist" do
      it "returns a valid feature object, but set to false (with a warning message)" do
        get "/v1/groups/non_existent/features/wibble"
        expect(last_response.status).to eq(200)

        data = JSON.parse(last_response.body)
        expect(data).to be_an_instance_of(Hash)
        expect(data.keys).to include("feature")
        expect(data.keys).to include("warning")

        expect(data["feature"]).to eq({
          "group"       => "non_existent",
          "name"        => "wibble",
          "description" => nil,
          "enabled"     => false
        })

        expect(data["warning"]).to eq("This group does not exist in the bandiera database.")
      end
    end

    context "when the group exists, but the feature doesn't" do
      it "returns a valid feature object, but set to false (with a warning message)" do
        get "/v1/groups/laserwolf/features/non_existent"
        expect(last_response.status).to eq(200)

        data = JSON.parse(last_response.body)
        expect(data).to be_an_instance_of(Hash)
        expect(data.keys).to include("feature")
        expect(data.keys).to include("warning")

        expect(data["feature"]).to eq({
          "group"       => "laserwolf",
          "name"        => "non_existent",
          "description" => nil,
          "enabled"     => false
        })

        expect(data["warning"]).to eq("This feature does not exist in the bandiera database.")
      end
    end
  end

  describe "PUT /v1/groups/:group_name/features/:feature_name" do
    context "when both the group and the feature exists" do
      context "with valid params" do
        it "updates the feature" do
          get "/v1/groups/shunter/features/stats_logging"
          before = JSON.parse(last_response.body)["feature"]

          put "/v1/groups/shunter/features/stats_logging", { feature: before.dup.merge({ "group" => "laserwolf" }) }
          expect(last_response.status).to eq(200)
          after1 = JSON.parse(last_response.body)["feature"]

          get "/v1/groups/laserwolf/features/stats_logging"
          after2 = JSON.parse(last_response.body)["feature"]

          expect(before).to_not eq(after1)
          expect(before).to_not eq(after2)
          expect(after1).to eq(after2)
        end
      end

      context "with invalid params" do
        it "returns an error" do
          feature_params = {
            "feature_name" => "new_feature_name"
          }

          put "/v1/groups/shunter/features/stats_logging", { feature: feature_params }
          expect(last_response.status).to eq(400)

          expected_data = { "error" => "Invalid parameters, required params are { 'feature' => { 'name' => 'FEATURE NAME', 'description' => 'FEATURE DESCRIPTION', 'enabled' => 'TRUE OR FALSE' }  }, optional params are { 'feature' => { 'group' => 'GROUP NAME' } }" }

          data = JSON.parse(last_response.body)
          expect(data).to eq(expected_data)
        end
      end
    end

    context "when the" do
      before do
        @params = {
          feature: {
            name:         "wibble_logging",
            description:  "Log me some wibble",
            enabled:      true
          }
        }
      end

      context "group doesn't exist" do
        it "returns a 404" do
          put "/v1/groups/wibble/features/wibble_logging", @params
          expect(last_response.status).to eq(404)
        end
      end

      context "feature doesn't exist" do
        it "returns a 404" do
          put "/v1/groups/shunter/features/wibble_logging", @params
          expect(last_response.status).to eq(404)
        end
      end
    end
  end

  describe "GET /v1/all" do
    it "returns all features in the database grouped by group" do
      expected_data = {
        "groups" => [
          {
            "name" => "laserwolf",
            "features" => [
              { "group" => "laserwolf", "name" => "enable_caching", "description" => "Enable caching", "enabled" => false }
            ]
          },
          {
            "name" => "pubserv",
            "features" => [
              { "group" => "pubserv", "name" => "show_search", "description" => "Show the search bar", "enabled" => true },
              { "group" => "pubserv", "name" => "show_subjects", "description" => "Show all subject related features", "enabled" => false },
              { "group" => "pubserv", "name" => "xmas_mode", "description" => "Xmas mode: SNOWFLAKES!", "enabled" => false }
            ]
          },
          {
            "name" => "shunter",
            "features" => [
              { "group" => "shunter", "name" => "stats_logging", "description" => "Log stats", "enabled" => true },
            ]
          }
        ]
      }

      get "/v1/all"
      expect(last_response.status).to eq(200)

      data = JSON.parse(last_response.body)

      data["groups"].each_index do |index|
        fetched  = data["groups"][index]
        expected = expected_data["groups"][index]

        expect(fetched["name"]).to eq(expected["name"])
        expect(fetched["features"]).to match_array(expected["features"])
      end
    end
  end
end
