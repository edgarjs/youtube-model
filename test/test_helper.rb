require 'rubygems'
require 'active_resource'
require 'test/unit'

gem 'fakeweb', ">= 1.2.6"

require 'fakeweb'
require 'ruby-debug'

class App < Hash
  attr_accessor :root, :env
end

Rails = App.new
Rails.root = File.expand_path(File.dirname(__FILE__))
Rails.env = "test"

Debugger.start

if Debugger.respond_to?(:settings)
  Debugger.settings[:autoeval] = true
  Debugger.settings[:autolist] = 1
end

require File.join(File.dirname(__FILE__),'../lib/you_tube_model.rb')


FakeWeb.allow_net_connect = false

def fixture_path
  File.expand_path(File.dirname(__FILE__)) + '/fixtures/'
end

def fake_responses(*file_names)
  file_names.flatten.collect do |file_name|
    if file_name.is_a? String
      {:body => File.read( fixture_path + file_name + '.xml' ), :content_type => 'application/xml'}
    else
      file_name
    end
  end
end

def register_uri(method, uri, *file_names)
  FakeWeb.register_uri(method, uri, fake_responses(*file_names))
end

def unregister_uri
  FakeWeb.clean_registry
end

