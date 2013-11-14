class SyslogFormatter < Logger::Formatter
  def initialize(args={})
    @format = "[%5s]: %s\n"

    if worker_no = args[:unicorn]
      @format = "[UNICORN:#{worker_no}] #{@format}"
    end
  end

  def call(severity, time, progname, msg)
    @format % [severity, msg2str(msg)]
  end

  protected

  def msg2str(msg)
    case msg
    when ::String
      msg
    when ::Exception
      "#{ msg.message } (#{ msg.class })\n" <<
      (msg.backtrace || []).join("\n")
    else
      msg.inspect
    end
  end
end
