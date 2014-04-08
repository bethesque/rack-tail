require "rack/tail/version"

require 'elif'
require 'time'
require 'rack/utils'
require 'rack/mime'

module Rack
  # Rack::File serves files below the +root+ directory given, according to the
  # path info of the Rack request.
  # e.g. when Rack::File.new("/etc") is used, you can access 'passwd' file
  # as http://localhost:9292/passwd
  #
  # Handlers can detect if bodies are a Rack::File, and use mechanisms
  # like sendfile on the +path+.

  class Tail

    SEPS = Regexp.union(*[::File::SEPARATOR, ::File::ALT_SEPARATOR].compact)
    ALLOWED_VERBS = %w[GET HEAD]

    attr_accessor :root
    attr_accessor :path
    attr_accessor :default_lines
    attr_accessor :cache_control

    alias :to_path :path

    def initialize(root, headers={}, default_mime = 'text/plain', default_lines = 50)
      @root = root
      @headers = headers
      @default_mime = default_mime
      @default_lines = default_lines
    end

    def call(env)
      dup._call(env)
    end

    F = ::File

    def _call(env)
      return fail(405, "Method Not Allowed") unless method_allowed?(env)
      return fail(403, "Forbidden") unless path_is_within_root?(env)

      @path = file_path(env)

      if available?
        serving(env)
      else
        fail(404, "File not found: #{path_info_for(env)}")
      end
    end

    def method_allowed? env
      ALLOWED_VERBS.include? env["REQUEST_METHOD"]
    end

    def available?
      begin
        F.file?(@path) && F.readable?(@path)
      rescue SystemCallError
        false
      end
    end

    def path_info_for env
      Utils.unescape(env["PATH_INFO"])
    end

    def path_is_within_root? env
      root = root env
      target = target_file env
      !target.relative_path_from(root).to_s.split(SEPS).any?{|p| p == ".."}
    end

    def target_file env
      path_info = Pathname.new("").join(*path_info_for(env).split(SEPS))
      root = root env
      root.join(path_info)
    end

    def root env
      Pathname.new(@root)
    end

    def file_path(env)
      target_file env
    end

    def serving(env)
      last_modified = F.mtime(@path).httpdate
      return [304, {}, []] if env['HTTP_IF_MODIFIED_SINCE'] == last_modified

      headers = { "Last-Modified" => last_modified }
      mime = Mime.mime_type(F.extname(@path), @default_mime)
      headers["Content-Type"] = mime if mime

      # Set custom headers
      @headers.each { |field, content| headers[field] = content } if @headers

      response = [ 200, headers, env["REQUEST_METHOD"] == "HEAD" ? [] : self ]
      response[1]["Content-Length"] = requested_size(env, response).to_s
      response
    end

    def requested_lines_size(env)
      (env.fetch("QUERY_STRING")[/\d+/] || default_lines).to_i
    end

    def tail_size_for line_count
      elif = Elif.new(@path)
      tail_size = 0
      line_count.times do
        begin
          tail_size += Rack::Utils.bytesize(elif.readline)
        rescue EOFError
          return tail_size
        end
      end
      tail_size - 1 # Don't include the first \n
    end


    def requested_size(env, response)
      # NOTE:
      #   We check via File::size? whether this file provides size info
      #   via stat (e.g. /proc files often don't), otherwise we have to
      #   figure it out by reading the whole file into memory.
      size = F.size?(@path) || Utils.bytesize(F.read(@path))
      #TODO handle invalid lines
      tail_size = tail_size_for requested_lines_size(env)

      if tail_size == size
        response[0] = 200
        @range = 0..size-1
      else
        start_byte = size - tail_size - 1
        @range = start_byte..size-1
        response[0] = 206
        response[1]["Content-Range"] = "bytes #{@range.begin}-#{@range.end}/#{size}"
        size = @range.end - @range.begin + 1
      end

      size
    end

    def each
      F.open(@path, "rb") do |file|
        file.seek(@range.begin)
        remaining_len = @range.end-@range.begin+1
        while remaining_len > 0
          part = file.read([8192, remaining_len].min)
          break unless part
          remaining_len -= part.length

          yield part
        end
      end
    end

    private

    def fail(status, body)
      body += "\n"
      [
        status,
        {
          "Content-Type" => "text/plain",
          "Content-Length" => body.size.to_s,
          "X-Cascade" => "pass"
        },
        [body]
      ]
    end

  end
end

