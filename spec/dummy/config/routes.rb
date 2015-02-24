Rails.application.routes.draw do

  mount BizWorkflowx::Engine => "/biz_workflowx"
  mount Commonx::Engine => "/commonx"
  mount Authentify::Engine => '/authentify'
  mount StateMachineLogx::Engine => '/sm_log'
  
  #resource :session
  
  root :to => "authentify/sessions#new"
  match '/signin',  :to => 'authentify/sessions#new'
  match '/signout', :to => 'authentify/sessions#destroy'
  match '/user_menus', :to => 'user_menus#index'
  match '/view_handler', :to => 'authentify/application#view_handler'
end
