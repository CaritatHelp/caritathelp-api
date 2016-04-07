Rails.application.routes.draw do

  apipie

  scope '/news' do
    post '/volunteer_status', to: 'news#volunteer_status'
    post '/assoc_status', to: 'news#assoc_status'
    post '/event_status', to: 'news#event_status'

    get '/', to: 'news#index'
    get '/:id', to: 'news#show'
    get '/:id/comments', to: 'news#comments'
  end

  scope '/comments' do
    post '/', to: 'comment#create'
    get '/:id', to: 'comment#show'
    put '/:id', to: 'comment#update'
    delete '/:id', to: 'comment#delete'
  end

  scope '/friendship' do
    post '/add', to: 'friendship#add'
    post '/reply', to: 'friendship#reply'
    delete '/remove', to: 'friendship#remove'
  end

  scope 'membership' do
    post '/join', to: 'membership#join_assoc'
    post '/reply_member', to: 'membership#reply_member'
    post '/invite', to: 'membership#invite'
    post '/reply_invite', to: 'membership#reply_invite'

    put '/upgrade', to: 'membership#upgrade'

    delete '/kick', to: 'membership#kick'
    delete '/leave', to: 'membership#leave_assoc'
  end

  scope '/volunteers' do
    get '/', to: 'volunteers#index'
    get '/search', to: 'volunteers#search'
    get '/:id', to: 'volunteers#show'
    get '/:id/friends', to: 'volunteers#friends'
    get '/:id/notifications', to: 'volunteers#notifications'
    get '/:id/associations', to: 'volunteers#associations'
    get '/:id/events', to: 'volunteers#events'

    post '/', to: 'volunteers#create'

    put '/:id', to: 'volunteers#update' 

    delete '/:id', to: 'volunteers#destroy'
    match '/', to: 'doc#index', via: :all
  end

  scope '/associations' do
    get '/', to: 'assocs#index'
    get '/search', to: 'assocs#search'
    get '/:id', to: 'assocs#show'
    get '/:id/members', to: 'assocs#members'
    get '/:id/notifications', to: 'assocs#notifications'
    get '/:id/events', to: 'assocs#events'

    post '/', to: 'assocs#create'

    put '/:id', to: 'assocs#update' 

    delete '/:id', to: 'assocs#destroy'
    match '/', to: 'doc#index', via: :all
  end

  scope '/events' do
    get '/', to: 'events#index'
    get '/search', to: 'events#search'
    get '/:id', to: 'events#show'
    get '/:id/guests', to: 'events#guests'
    get '/:id/notifications', to: 'events#notifications'
    
    post '/', to: 'events#create'

    put '/:id', to: 'events#update'
  end

  scope '/guests' do
    post '/join', to: 'guests#join'
    post '/reply_guest', to: 'guests#reply_guest'
    post '/invite', to: 'guests#invite'
    post '/reply_invite', to: 'guests#reply_invite'

    put '/upgrade', to: 'guests#upgrade'

    delete '/kick', to: 'guests#kick'    
    delete '/leave', to: 'guests#leave_event'
  end
  
  scope '/login' do
    post '/', to: 'login#index'
    match '/', to: 'doc#index', via: :all
  end
  
  scope '/logout' do
    post '/', to: 'logout#index'
    match '/', to: 'doc#index', via: :all
  end

  get 'doc/', to: 'doc#index'
  get '/errors', to: 'doc#errors'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
