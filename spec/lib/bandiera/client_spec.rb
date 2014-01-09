require "spec_helper"

describe Bandiera::Client do
  let(:base_uri)  { "http://bandiera.com" }
  let(:api_uri)   { "#{base_uri}/api" }
  let(:logger)    { double }
  subject         { Bandiera::Client.new(api_uri, logger) }

  describe "#get_all" do
    before do
      @url = "#{api_uri}/v1/all"
    end

    context "all is ok" do
      it "returns all features in the Bandiera instance (as a hash of arrays)" do
        returned_json = {
          "groups" => [
            {
              "name"     => "pubserv",
              "features" => [
                { "group" => "pubserv", "name" => "show_search", "description" => "Show the search bar", "enabled" => true },
              ]
            }
          ]
        }

        stub = stub_request(:get, @url).to_return(body: JSON.generate(returned_json), headers: { "Content-Type" => "application/json" })

        response = subject.get_all

        expect(response).to be_an_instance_of(Hash)
        expect(response["pubserv"]).to be_an_instance_of(Array)
        expect(response["pubserv"].first).to be_an_instance_of(Bandiera::Feature)

        stub.should have_been_requested
      end
    end

    context "bandiera is down" do
      it "raises an error" do
        stub_request(:get, @url).to_return(status: [0, ""])
        expect{ subject.get_all }.to raise_error(Bandiera::Client::ServerDownError)
      end
    end

    context "bandiera raises an error" do
      it "raises an error" do
        stub_request(:get, @url).to_return(status: [500, "Internal Server Error"])
        expect{ subject.get_all }.to raise_error(Bandiera::Client::RequestError)
      end
    end

    context "bandiera times out" do
      it "raises an error" do
        stub_request(:get, @url).to_timeout
        expect{ subject.get_all }.to raise_error(Bandiera::Client::TimeOutError)
      end
    end
  end

  describe "#get_features_for_group" do
    before do
      @group = "pubserv"
      @url   = "#{api_uri}/v1/groups/#{@group}/features"
    end

    context "all is ok" do
      context "and the group exists with features" do
        it "returns all features for the group" do
          returned_json = {
            "features"=> [
              { "group" => "pubserv", "name" => "log-stats", "description" => "Log statistics.", "enabled" => false },
              { "group" => "pubserv", "name" => "show-search", "description" => "Show the search bar.", "enabled" => true }
            ]
          }

          stub = stub_request(:get, @url).to_return(body: JSON.generate(returned_json), headers: { "Content-Type" => "application/json" })

          response = subject.get_features_for_group(@group)

          expect(response).to be_an_instance_of(Array)
          expect(response.first).to be_an_instance_of(Bandiera::Feature)

          stub.should have_been_requested
        end
      end

      context "but the group doesn't exist" do
        it "returns an empty array and issues a warning" do
          stub_request(:get, @url).to_return(status: [404, "Not Found"])

          logger.should_receive(:warn).once

          response = subject.get_features_for_group(@group)

          expect(response).to be_an_instance_of(Array)
          expect(response).to be_empty
        end
      end
    end

    context "bandiera is down" do
      it "returns an empty array and issues a warning" do
        stub_request(:get, @url).to_return(status: [0, ""])

        logger.should_receive(:warn).once

        response = subject.get_features_for_group(@group)

        expect(response).to be_an_instance_of(Array)
        expect(response).to be_empty
      end
    end

    context "bandiera times out" do
      it "returns an empty array and issues a warning" do
        stub_request(:get, @url).to_timeout

        logger.should_receive(:warn).once

        response = subject.get_features_for_group(@group)

        expect(response).to be_an_instance_of(Array)
        expect(response).to be_empty
      end
    end
  end

  describe "#get_feature" do
    before do
      @group   = "pubserv"
      @feature = "log-stats"
      @url     = "#{api_uri}/v1/groups/#{@group}/features/#{@feature}"
    end

    context "all is ok" do
      context "and the group/feature exists" do
        it "returns the feature" do
          returned_json = {
            "feature" => {
              "group"       => @group,
              "name"        => @feature,
              "description" => "Enable logging of statistics.",
              "enabled"     => true
            }
          }

          stub = stub_request(:get, @url).to_return(body: JSON.generate(returned_json), headers: { "Content-Type" => "application/json" })

          response = subject.get_feature(@group, @feature)

          expect(response).to be_an_instance_of(Bandiera::Feature)
          expect(response.name).to eq(@feature)
          expect(response.group).to eq(@group)
          expect(response.enabled?).to be_true

          stub.should have_been_requested
        end
      end

      context "but the group doesn't exist" do
        it "returns a 'default', deactivated feature with a warning" do
          returned_json = {
            "warning" => "This group does not exist in the bandiera database.",
            "feature" => {
              "group"       => @group,
              "name"        => @feature,
              "description" => nil,
              "enabled"     => false
            }
          }

          stub = stub_request(:get, @url).to_return(body: JSON.generate(returned_json), headers: { "Content-Type" => "application/json" })

          logger.should_receive(:warn).once

          response = subject.get_feature(@group, @feature)

          expect(response).to be_an_instance_of(Bandiera::Feature)
          expect(response.name).to eq(@feature)
          expect(response.group).to eq(@group)
          expect(response.enabled?).to be_false

          stub.should have_been_requested
        end
      end

      context "and the group exists, but the feature doesn't" do
        it "returns a 'default', deactivated feature with a warning" do
          returned_json = {
            "warning" => "This feature does not exist in the bandiera database.",
            "feature" => {
              "group"       => @group,
              "name"        => @feature,
              "description" => nil,
              "enabled"     => false
            }
          }

          stub = stub_request(:get, @url).to_return(body: JSON.generate(returned_json), headers: { "Content-Type" => "application/json" })

          logger.should_receive(:warn).once

          response = subject.get_feature(@group, @feature)

          expect(response).to be_an_instance_of(Bandiera::Feature)
          expect(response.name).to eq(@feature)
          expect(response.group).to eq(@group)
          expect(response.enabled?).to be_false

          stub.should have_been_requested
        end
      end
    end

    context "bandiera is down" do
      it "returns a 'default', deactivated feature with a warning" do
        stub_request(:get, @url).to_return(status: [0, ""])

        logger.should_receive(:warn).once

        response = subject.get_feature(@group, @feature)

        expect(response).to be_an_instance_of(Bandiera::Feature)
        expect(response.enabled?).to be_false
      end
    end

    context "bandiera times out" do
      it "returns a 'default', deactivated feature with a warning" do
        stub_request(:get, @url).to_timeout

        logger.should_receive(:warn).once

        response = subject.get_feature(@group, @feature)

        expect(response).to be_an_instance_of(Bandiera::Feature)
        expect(response.enabled?).to be_false
      end
    end
  end
end
