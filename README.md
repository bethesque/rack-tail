# Rack::Tail

Like Rack::File, but it serves the last lines of a file.

## Installation

Add this line to your application's Gemfile:

    gem 'rack-tail'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack-tail

## Usage

Rack::Tail serves files below the +root+ directory given, according to the path info of the Rack request.
e.g. when Rack::File.new("/etc") is used, you can access 'passwd' file
as http://localhost:9292/passwd

Great idea...

Be careful how you use this.

Here's a legitimate example.

```ruby
require 'rack/tail'

app = map "/logging" do
  run Rack::Tail.new("logs")
end

run app

# Now open http://localhost:9292/logging/app.log?n=2

```

Note that you cannot hack the URL to access any files that are outside the root directory specified in the constructor.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
