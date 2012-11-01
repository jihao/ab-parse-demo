#!/usr/bin/env ruby
require 'json'
require 'sinatra'
require 'rack-flash'
require 'rest-client'

require "erb"
include ERB::Util
require "cgi"

application_id = ENV['APPLICATION_ID_AB'] || "5o93Gh8W63z2npIUErJvwwYz2IkpJIba6eL1ROAa"
api_key        = ENV['REST_API_KEY_AB'] || "E7Xg39e89nYjGhc1V0fXeukHMXOAo5SCkrQAgiKM"
AUTH_HASH =  {"X-Parse-Application-Id" => application_id, "X-Parse-REST-API-Key" => api_key}
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

  where = url_encode('where={"owner":{"__type":"Pointer","className":"_User","objectId":"EXmRl19aJq"}}')
  url = 'https://api.parse.com/1/classes/AddressBook'.concat('?').concat(where)
  puts url
  #address_list = RestClient.get url, {"X-Parse-Application-Id" => "5o93Gh8W63z2npIUErJvwwYz2IkpJIba6eL1ROAa", "X-Parse-REST-API-Key" => "E7Xg39e89nYjGhc1V0fXeukHMXOAo5SCkrQAgiKM"}
  address_list = '{"results":[{"address":"No.1068 Tianshan Road West","cellphone":"13788889999","name":"Steve","owner":{"__type":"Relation","className":"_User"},"createdAt":"2012-10-10T07:53:36.824Z","updatedAt":"2012-10-31T08:26:55.275Z","objectId":"8weFDfQ343"},{"address":"No.1068 Tianshan Road West","cellphone":"13799998888","name":"Tim","owner":{"__type":"Relation","className":"_User"},"createdAt":"2012-10-31T02:59:44.762Z","updatedAt":"2012-10-31T08:26:53.275Z","objectId":"Yb7TdS01Mn"}]}';
  obj = JSON.parse address_list
  @address_list = obj["results"]
  puts @address_list.inspect

  erb :home
end

get '/index' do
  erb :index
end
get '/abc' do
  protected!
  
  erb :abc
end

get '/signin' do
  erb :signin
end

post '/signin' do
  name = params[:email]
  password = params[:password] 

  if name.empty? || password.empty? 
    flash[:notice] = "fields should not be empty"
    return erb :signin
  end
  #query = CGI::escape('username='.concat(name).concat('&password=').concat(password))
  query = 'password='+password+'&'+'username='+name
  url = 'https://api.parse.com/1/login'.concat('?').concat(query)
  puts url
  puts AUTH_HASH
  result = RestClient.get url, AUTH_HASH
  @user = JSON.parse result
  puts @user
  session[:user] = @user
  #{"phone"=>"415-392-0202", "username"=>"test", "createdAt"=>"2012-10-31T02:45:10.402Z", "updatedAt"=>"2012-10-31T06:25:56.191Z", "objectId"=>"EXmRl19aJq", "sessionToken"=>"3cbkov9ol4o1iaungkmni0ssc"}
  redirect "/home"
end

get '/home' do
  if session[:user].nil?
    redirect "/signin"
  end
  objectId = session[:user]["objectId"]

  where = url_encode('where={"owner":{"__type":"Pointer","className":"_User","objectId":"'+objectId+'"}}')
  url = 'https://api.parse.com/1/classes/AddressBook'.concat('?').concat(where)
  puts url
  address_list = RestClient.get url, AUTH_HASH
  #address_list = '{"results":[{"address":"No.1068 Tianshan Road West","cellphone":"13788889999","name":"Steve","owner":{"__type":"Relation","className":"_User"},"createdAt":"2012-10-10T07:53:36.824Z","updatedAt":"2012-10-31T08:26:55.275Z","objectId":"8weFDfQ343"},{"address":"No.1068 Tianshan Road West","cellphone":"13799998888","name":"Tim","owner":{"__type":"Relation","className":"_User"},"createdAt":"2012-10-31T02:59:44.762Z","updatedAt":"2012-10-31T08:26:53.275Z","objectId":"Yb7TdS01Mn"}]}';
  obj = JSON.parse address_list
  @address_list = obj["results"]
  puts @address_list.inspect

  erb :home
end
get '/signup' do
  erb :signup
end


post '/create' do
  name = params[:name]
  email = params[:email]
  cellphone = params[:cellphone] 
  objectId = session[:user]["objectId"]
  result = RestClient.post "https://api.parse.com/1/classes/AddressBook", 
    {"name"=>name,"cellphone"=>cellphone,"email"=>email,"owner"=>{"__op"=>"AddRelation","objects"=>[{"__type"=>"Pointer","className"=>"_User","objectId"=>objectId}]}}.to_json, 
    :content_type => :json, :accept => :json, "X-Parse-Application-Id" => application_id, "X-Parse-REST-API-Key" => api_key
  @result = JSON.parse result
  puts @result
  
  redirect "/home"
end
post '/edit' do
  name = params[:name]
  email = params[:email]
  cellphone = params[:cellphone] 
  objectId = params[:objectId]
  puts objectId
  result = RestClient.put "https://api.parse.com/1/classes/AddressBook/".concat(objectId), 
    {"name"=>name,"cellphone"=>cellphone,"email"=>email}.to_json, 
    :content_type => :json, :accept => :json, "X-Parse-Application-Id" => application_id, "X-Parse-REST-API-Key" => api_key
  @result = JSON.parse result
  puts @result
  
  redirect "/home"
end
post '/destroy' do
  objectId = params[:objectId]
  result = RestClient.delete "https://api.parse.com/1/classes/AddressBook/".concat(objectId), AUTH_HASH
  @result = JSON.parse result
  puts @result
  
  redirect "/home"
end