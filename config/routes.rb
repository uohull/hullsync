# require 'resque/server'


Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :notifications
  resources :dips
  # mount Resque::Server.new, at: '/jobs'
end
