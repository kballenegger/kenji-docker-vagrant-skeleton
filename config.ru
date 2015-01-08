# vim: ft=ruby
require 'rubygems'
require 'bundler/setup'
require 'rack'
require 'rack/cors'
require 'rack-json-logs'
require 'kenji'

# NOTE: feel free to delete this

use Rack::JsonLogs, pretty_print: (ENV['env'] != 'live'),
                    print_options: {
                      stdout: true,
                      stderr: true,
                      from: true,
                      trace: true,
                      duration: true,
                      events: true,
                    }

use Rack::Cors do
  allow do
    origins '*'
    resource '*', :headers => :any, :methods => [:get, :post, :put, :delete, :patch]
  end
end

$: << File.expand_path(File.dirname(__FILE__))
require 'controllers/root'

run Kenji::App.new(catch_exceptions: false, auto_cors: false,
                   root_controller: RootController)
