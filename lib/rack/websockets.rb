require 'faye/websocket'
require 'bandiera/websockets'

module Rack
  class Websockets
    def initialize(app)
      @app = app
      Bandiera::Websockets.init
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        Bandiera::Websockets.create_server(env)
      else
        @app.call(env)
      end
    end
  end
end
