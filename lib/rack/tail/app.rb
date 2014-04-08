require "rack/tail/request_handler"

module Rack

  module Tail

    class App

      attr_accessor :cache_control
      attr_reader :root

      def initialize(root, headers, default_mime, default_lines)
        @root = root
        @headers = headers
        @default_mime = default_mime
        @default_lines = default_lines
      end

      def call(env)
        RequestHandler.new(env, @root, @headers, @default_mime, @default_lines).call
      end

    end

  end

end

