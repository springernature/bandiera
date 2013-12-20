$:.unshift File.join(__FILE__, "../lib")

require "bandiera"

run Rack::URLMap.new(
  "/api" => Bandiera::API
)

