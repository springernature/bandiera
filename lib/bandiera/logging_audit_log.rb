module Bandiera
  class LoggingAuditLog
    def initialize(logger)
      @logger = logger
    end

    def record(audit_context, action, object_name, params = {})
      @logger.log("AUDIT [#{audit_context.user_id}] #{action} #{object_name}#{format(params)}")
    rescue
      # ignored
    end

    private

    def format(params)
      if params && !params.empty?
        ' (' + params.map {|key, value| "#{key}: #{value}"}.join(', ') + ')'
      else
        ''
      end
    end
  end
end
