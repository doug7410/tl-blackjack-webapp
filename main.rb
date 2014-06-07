require 'rubygems'
require 'sinatra' 

set :sessions, true

get '/' do
  "654654654654"
end

get '/home' do
	"home"
end

get '/template' do
	erb :mytemplate, :layout => :new_layout
end

get '/nested_template' do 
 	erb :"/users/profile"#, :layout => false
end

get '/nothere' do
	redirect '/home'
end

get '/form' do
	erb :form
end

post '/myaction' do
	puts params['name']
end

get '/simple_text' do
	"here is some really simple_text!"
end

get '/xbox' do
	erb :xbox1
end

get '/games' do
	redirect '/xbox'
end