Rails.application.routes.draw do
  root 'welcome#index'
  get '/create' => 'game#create'
  get '/join' => 'game#join'
  get '/start' => 'game#start'
  get '/info' => 'game#info'
  get '/play' => 'game#play'
end
