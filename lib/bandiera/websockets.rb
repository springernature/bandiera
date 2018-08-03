require 'faye/websocket'
require 'json'

module Bandiera
  class Websockets
    class Client
      attr_reader :group

      def initialize(env)
        @socket = Faye::WebSocket.new(env)
        @group = nil

        @socket.on :message, method(:on_message)
        @socket.on :close,   method(:on_close)
      end

      def send(event)
        @socket.send(event)
      end

      def rack_response
        @socket.rack_response
      end

      private

      def on_message(event)
        message = JSON.parse(event.data)

        case message["command"]
        when "subscribe"
          puts "subscribing to the #{message["group"]}"
          @group = message["group"]
        end
      end

      def on_close(event)
        p [:close, event.code, event.reason]
        @clients.delete(client)
      end
    end

    class << self
      def init
        @clients = []
      end

      def create_server(env)
        @clients << Client.new(env)
        @clients.last.rack_response
      end

      def publish(group, feature)
        @clients.each do |c|
          c.send(feature) if c.group == group
        end
      end
    end
  end
end
