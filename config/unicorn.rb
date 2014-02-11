# listen on both a Unix domain socket and a TCP port,
# we use a shorter backlog for quicker failover when busy
listen "/tmp/bandiera.sock", :backlog => 64

port = ENV["PORT"] || 5000
listen port.to_i, :tcp_nopush => true

# nuke workers after 30 seconds instead of 60 seconds (the default)
timeout 30

# combine Ruby 2.0.0 or REE with "preload_app true" for memory savings
# http://rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and GC.copy_on_write_friendly = true

# Switch the unicorn logger.
if ENV["BANDIERA_SYSLOG"]
  require "syslog-logger"

  class ::Logger::Syslog; alias_method :write, :info; end

  syslog_logger       = Logger::Syslog.new("bandiera", Syslog::LOG_LOCAL0)
  syslog_logger.level = Logger::INFO
  logger syslog_logger
end

no_of_processes = ENV["BANDIERA_PROCESSES"] || 1
worker_processes no_of_processes.to_i

if ENV["BANDIERA_DIR"]
  # Help ensure your application will always spawn in the symlinked
  # "current" directory that Capistrano sets up.
  working_directory ENV["BANDIERA_DIR"]
end

if ENV["BANDIERA_PID"]
  # feel free to point this anywhere accessible on the filesystem
  pid ENV["BANDIERA_PID"]
end

