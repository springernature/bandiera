module Bandiera
  class LoggingAuditLog
    def initialize(db = Db.connect)
      @db = db
    end

    def record(audit_context, action, object_name, params = {})
      audit_record = AuditRecord.new(
        user: audit_context.user_id,
        action: action,
        object: object_name.to_s,
        params: format(params)
      )
      audit_record.save
    rescue => e
      Bandiera.logger.error("Audit logging failed: #{e.message}")
    end

    private

    def format(params)
      if params && !params.empty?
        params.to_json
      else
        nil
      end
    end

  end
end
