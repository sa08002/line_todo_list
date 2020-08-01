Rails.application.routes.draw do
  resources :tasks

  root "tasks#index"

  post "/callback" => "line_bot#callback"

end
