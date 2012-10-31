#!/usr/bin/env ruby
require 'sinatra'
require 'rack-flash'
require 'rest-client'

require "erb"
include ERB::Util

application_id = ENV['APPLICATION_ID_IMESSGAE']
api_key        = ENV['REST_API_KEY_IMESSGAE']
RestClient.proxy = ENV['http_proxy']

set :public_folder, File.dirname(__FILE__) + '/static'
enable :sessions
use Rack::Flash

BASIC_PASSWORD = ENV['BASIC_PASSWORD'] || 'test123yrd'

helpers do
  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, "Not authorized\n"])
    end
  end
  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', BASIC_PASSWORD]
  end
end


get '/' do
#curl -X GET \
# -H "X-Parse-Application-Id: 5o93Gh8W63z2npIUErJvwwYz2IkpJIba6eL1ROAa" \
# -H "X-Parse-REST-API-Key: E7Xg39e89nYjGhc1V0fXeukHMXOAo5SCkrQAgiKM" https://api.parse.com/1/classes/AddressBook/8weFDfQ343

# curl -X GET \
#   -H "X-Parse-Application-Id: 5o93Gh8W63z2npIUErJvwwYz2IkpJIba6eL1ROAa" \
#   -H "X-Parse-REST-API-Key: E7Xg39e89nYjGhc1V0fXeukHMXOAo5SCkrQAgiKM" \
#   -G --data-urlencode 'where={"owner":{"__type":"Pointer","className":"_User","objectId":"EXmRl19aJq"}}' \
#   https://api.parse.com/1/classes/AddressBook

  @resp = RestClient.get 'https://api.parse.com/1/classes/AddressBook/8weFDfQ343', 
    {"X-Parse-Application-Id" => "5o93Gh8W63z2npIUErJvwwYz2IkpJIba6eL1ROAa", "X-Parse-REST-API-Key" => "E7Xg39e89nYjGhc1V0fXeukHMXOAo5SCkrQAgiKM"}
  puts @resp

  where = url_encode('where={"owner":{"__type":"Pointer","className":"_User","objectId":"EXmRl19aJq"}}')
  url = 'https://api.parse.com/1/classes/AddressBook'.concat('?').concat(where)
  puts url
  @address_list = RestClient.get url, {"X-Parse-Application-Id" => "5o93Gh8W63z2npIUErJvwwYz2IkpJIba6eL1ROAa", "X-Parse-REST-API-Key" => "E7Xg39e89nYjGhc1V0fXeukHMXOAo5SCkrQAgiKM"}
  puts @address_list

  erb :index
end

get '/abc' do
  protected!
  
  erb :abc
end
