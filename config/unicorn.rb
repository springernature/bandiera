port            = Integer(ENV['PORT'] || 5000)
no_of_processes = Integer(ENV['PROCESSES'] || 1)
unix_socket     = ENV['SOCKET'] || '/tmp/bandiera.sock'

listen            port, tcp_nopush: true
listen            unix_socket
timeout           15
preload_app       true
worker_processes  no_of_processes

if ENV['USE_SYSLOG']
  require 'syslog-logger'

  class Logger::Syslog; alias_method :write, :info; end

  syslog_logger       = Logger::Syslog.new('bandiera', Syslog::LOG_LOCAL0)
  syslog_logger.level = Logger::INFO
  logger syslog_logger
end

if ENV['WORKING_DIR']
  working_directory ENV['WORKING_DIR']
end

if ENV['PID_FILE']
  pid ENV['PID_FILE']
end
