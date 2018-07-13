require 'json'

class Logger
  class StackdriverJsonFormatter < Logger::Formatter
    def call(severity, _time, _progname, msg)
      json = { severity: severity, message: msg2str(msg) }
      "#{JSON.generate(json)}\n"
    end

    protected

    def msg2str(msg)
      case msg
      when String
        msg
      when Exception
        "#{msg.message} (#{msg.class})\n#{(msg.backtrace || []).join("\n")}"
      else
        msg.inspect
      end
    end
  end
end
