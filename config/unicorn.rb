APP_ROOT = File.expand_path(File.dirname(File.dirname(__FILE__)))

$LOAD_PATH.unshift File.join(APP_ROOT, 'lib')

require 'bandiera'

port            = Integer(ENV['PORT'] || 5000)
no_of_processes = Integer(ENV['PROCESSES'] || 1)
unix_socket     = ENV['SOCKET'] || '/tmp/bandiera.sock'

listen            port, tcp_nopush: true
listen            unix_socket
timeout           15
worker_processes  no_of_processes
logger            Bandiera.logger
working_directory ENV['WORKING_DIR'] if ENV['WORKING_DIR']
pid               ENV['PID_FILE'] if ENV['PID_FILE']
preload_app       true

before_fork do |server, worker|
  Bandiera::Db.disconnect
end

after_fork do |server, worker|
  Bandiera::Db.connect
end
