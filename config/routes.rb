Rails.application.routes.draw do
  root to: 'consents#index'
  resources :consents

  get 'consentimiento', to: 'consents#consentimiento'
end
