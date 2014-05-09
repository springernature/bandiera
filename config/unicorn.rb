$LOAD_PATH.unshift File.join(__FILE__, '../../lib')

require 'bandiera'

port            = Integer(ENV['PORT'] || 5000)
no_of_processes = Integer(ENV['PROCESSES'] || 1)
unix_socket     = ENV['SOCKET'] || '/tmp/bandiera.sock'

listen            port, tcp_nopush: true
listen            unix_socket
timeout           15
preload_app       true
worker_processes  no_of_processes

if ENV['USE_SYSLOG']
  require 'macmillan/utils/logger/factory'
  require 'macmillan/utils/logger/formatter'

  syslog_logger           = Macmillan::Utils::Logger::Factory.build_logger(:syslog, tag: 'bandiera')
  syslog_logger.formatter = Macmillan::Utils::Logger::Formatter.new
  syslog_logger.level     = Logger::INFO
  logger(syslog_logger)
end

before_fork do |server, worker|
  Bandiera::Db.disconnect!
end

after_fork do |server, worker|
  Bandiera::Db.connection
end

if ENV['WORKING_DIR']
  working_directory ENV['WORKING_DIR']
end

if ENV['PID_FILE']
  pid ENV['PID_FILE']
end
