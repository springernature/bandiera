# frozen_string_literal: true

require 'rack/body_proxy'

module Rack
  # Rack::NotSoCommonLogger forwards every request to the given +app+, and
  # logs a line in something similar to the
  # {Apache common log format}[http://httpd.apache.org/docs/1.3/logs.html#common]
  # to the +logger+.  This formatter just ensures that user identifiable
  # information like ip addresses and identities are not logged.
  #
  # Rack::CommonLogger string:
  #   127.0.0.1 - - [15/May/2018:13:15:29 +0100] "GET / HTTP/1.1" 404 510 0.1061
  #
  # Rack::NotSoCommonLogger string:
  #   [15/May/2018:13:15:29 +0100] "GET / HTTP/1.1" 404 510 0.1061
  #
  # This ensures we don't log ip addresses and user identities if we're using
  # basic auth
  #
  # If +logger+ is nil, NotSoCommonLogger will fall back +rack.errors+, which is
  # an instance of Rack::NullLogger.
  #
  # +logger+ can be any class, including the standard library Logger, and is
  # expected to have either +write+ or +<<+ method, which accepts the CommonLogger::FORMAT.
  # According to the SPEC, the error stream must also respond to +puts+
  # (which takes a single argument that responds to +to_s+), and +flush+
  # (which is called without arguments in order to make the error appear for
  # sure)
  class NotSoCommonLogger
    FORMAT = [
      %([%<timestamp>s]),
      %("%<request_method>s %<path>s%<query_string>s %<http_version>s"),
      %(%<http_status>d),
      %(%<content_length>s),
      %(%<duration>0.4f),
      "\n"
    ].join(' ')

    def initialize(app, logger = nil)
      @app = app
      @logger = logger
    end

    def call(env)
      began_at = Utils.clock_time
      status, header, body = @app.call(env)
      header = Utils::HeaderHash.new(header)
      body = BodyProxy.new(body) { log(env, status, header, began_at) }
      [status, header, body]
    end

    private

    def log(env, status, header, began_at)
      msg    = log_message(env, status, header, began_at)
      logger = @logger || env[RACK_ERRORS]
      # Standard library logger doesn't support write but it supports << which actually
      # calls to write on the log device without formatting
      if logger.respond_to?(:write)
        logger.write(msg)
      else
        logger << msg
      end
    end

    def log_message(env, status, header, began_at)
      format(
        FORMAT,
        timestamp:      log_time,
        request_method: env[REQUEST_METHOD],
        path:           env[PATH_INFO],
        query_string:   query_string(env),
        http_version:   env[HTTP_VERSION],
        http_status:    status.to_s[0..3],
        content_length: extract_content_length(header),
        duration:       Utils.clock_time - began_at
      )
    end

    def query_string(env)
      return '' if env[QUERY_STRING].empty?

      params = Rack::Utils.parse_nested_query(env[QUERY_STRING])

      if ENV['SHOW_USER_GROUP_IN_LOGS'] != 'true' && params['user_group']
        params['user_group'] = 'XXXXX'
      end

      "?#{Rack::Utils.build_nested_query(params)}"
    end

    def log_time
      Time.now.strftime('%d/%b/%Y:%H:%M:%S %z')
    end

    def extract_content_length(headers)
      (value = headers[CONTENT_LENGTH]) || (return '-')
      value.to_s == '0' ? '-' : value
    end
  end
end
