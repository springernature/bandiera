$LOAD_PATH.unshift File.join(__FILE__, "../lib")

require "bandiera"

run Rack::URLMap.new(
  "/"    => Bandiera::GUI,
  "/api" => Bandiera::API
)

