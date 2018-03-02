module Bandiera
  class WebAuditContext

    def initialize(request)
      @request = request
    end

    def user_id
      @request.ip
    end

  end
end
