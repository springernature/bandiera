require "typhoeus"
require "json"

require_relative "feature"

module Bandiera
  class Client
    class RequestError < StandardError; end
    class ServerDownError < StandardError; end
    class TimeOutError < StandardError; end

    HANDLED_EXCEPTIONS = [RequestError, ServerDownError, TimeOutError]

    attr_accessor :timeout

    def initialize(base_uri="http://localhost", logger=Logger.new($stdout))
      @base_uri = base_uri
      @logger   = logger
      @timeout  = 0.02 # 20ms default timeout

      @base_uri << "/api" unless @base_uri.match(/\/api$/)
    end

    def enabled?(group, feature)
      get_feature(group, feature).enabled?
    end

    def get_all
      groups = {}

      get("/v1/all")["groups"].each do |grp|
        group    = grp["name"]
        features = grp["features"].map { |f| Bandiera::Feature.new(f["name"], group, f["description"], f["enabled"]) }
        groups[group] = features
      end

      groups
    end

    def get_features_for_group(group)
      error_msg_prefix = "[Bandiera::Client#get_features_for_group] '#{group}'"
      default_response = []

      handle_exceptions(error_msg_prefix, default_response) do
        get("/v1/groups/#{group}/features")["features"].map do |f|
          Bandiera::Feature.new(f["name"], group, f["description"], f["enabled"])
        end
      end
    end

    def get_feature(group, feature)
      error_msg_prefix = "[Bandiera::Client#get_feature] '#{group} / #{feature}'"
      default_response = Bandiera::Feature.new(feature, group, nil, false)

      handle_exceptions(error_msg_prefix, default_response) do
        res = get("/v1/groups/#{group}/features/#{feature}")

        @logger.warn "#{error_msg_prefix} - #{res["warning"]}" if res["warning"]

        Bandiera::Feature.new(feature, group, res["feature"]["description"], res["feature"]["enabled"])
      end
    end

    private

    def handle_exceptions(error_msg_prefix, return_upon_error, &block)
      begin
        yield
      rescue *HANDLED_EXCEPTIONS => error
        @logger.warn("#{error_msg_prefix} - #{error.message}")
        return_upon_error
      end
    end

    def get(path)
      url     = "#{@base_uri}#{path}"
      request = Typhoeus::Request.new(url, timeout: timeout, connecttimeout: timeout)

      request.on_complete do |response|
        if response.success?
          # w00t
        elsif response.timed_out?
          raise TimeOutError.new("TimeOut occured requesting '#{url}'")
        elsif response.code == 0
          raise ServerDownError.new("Bandiera appears to be down.")
        else
          raise RequestError.new("GET request to '#{url}' returned #{response.code}")
        end
      end

      JSON.parse(request.run.body)
    end
  end
end
