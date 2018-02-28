Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'stocks#index'
  # resources :stocks
  get    'stocks/create',    to: 'stocks#index'
  post   '/stocks/create',   to: 'stocks#create'
end
