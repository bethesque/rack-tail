require 'rack/tail'

app = map "/logging" do
  run Rack::Tail.new("logs")
end

run app

# Now open http://localhost:9292/logging/app.log?n=2