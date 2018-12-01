require 'sinatra'

set :port, 8080
set :bind, '0.0.0.0'
set :traps, false
set :server, :puma
set :show_exceptions, false

get '/hello' do
  "Hello from #{ENV['AWS_AVAILABILITY_ZONE']}"
end

get '/ping' do
  'OK'
end

Sinatra::Application.run!
