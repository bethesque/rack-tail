require "rack/tail/version"
require "rack/tail/app"

module Rack

  # Rack::Tail is shamelessly ripped off Rake::File

  # Rack::Tail serves files below the +root+ directory given, according to the
  # path info of the Rack request.
  # e.g. when Rack::File.new("/etc") is used, you can access 'passwd' file
  # as http://localhost:9292/passwd

  module Tail

    def self.new(root, headers={}, default_mime = 'text/plain', default_lines = 50)
      App.new(root, headers, default_mime, default_lines)
    end

  end
end

