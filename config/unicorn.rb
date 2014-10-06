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
logger            Bandiera.logger

before_fork do |server, worker|
  Bandiera::Db.disconnect
end

after_fork do |server, worker|
  Bandiera::Db.connect
end

if ENV['WORKING_DIR']
  working_directory ENV['WORKING_DIR']
end

if ENV['PID_FILE']
  pid ENV['PID_FILE']
end
