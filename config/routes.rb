Rails.application.routes.draw do
  get '/create' => 'game#create'
  get '/join' => 'game#join'
  get '/start' => 'game#start'
  get '/info' => 'game#info'
end
