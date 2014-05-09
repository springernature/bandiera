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
  syslog_logger.formatter = Macmillan::Utils::Logger::Formatter.new('[UNICORN:M]')
  syslog_logger.level     = Logger::INFO
  logger(syslog_logger)
end

after_fork do |server, worker|
  if ENV['USE_SYSLOG']
    syslog_logger           = Macmillan::Utils::Logger::Factory.build_logger(:syslog, tag: 'bandiera')
    syslog_logger.formatter = Macmillan::Utils::Logger::Formatter.new("[UNICORN:#{worker.nr}]")
    syslog_logger.level     = Logger::INFO
    logger(syslog_logger)
  end
end

if ENV['WORKING_DIR']
  working_directory ENV['WORKING_DIR']
end

if ENV['PID_FILE']
  pid ENV['PID_FILE']
end
