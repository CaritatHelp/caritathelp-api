Rails.application.routes.draw do

  get 'pictures/create'

  get 'pictures/delete'

  get 'pictures/update'

  apipie

  scope '/' do
    get '/search', to: 'volunteers#search'
    get '/friend_requests', to: 'volunteers#friend_requests'
    get '/notifications', to: 'volunteers#notifications'
    
    # followers routes
    post '/follow', to: 'followers#follow'

    delete '/unfollow', to: 'followers#unfollow'

    put '/block', to: 'followers#block'
  end

  scope 'notifications' do
    put '/:id/read', to: 'notifications#read'
  end

  scope '/news' do
    post '/wall_message', to: 'news#wall_message'

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

  scope '/shelters' do
    post '/', to: 'shelters#create'
    get '/', to: 'shelters#index'
    get '/search', to: 'shelters#search'
    get '/:id', to: 'shelters#show'
    get '/:id/pictures', to: 'shelters#pictures'
    get '/:id/main_picture', to: 'shelters#main_picture'
    put '/:id', to: 'shelters#update'
    delete '/:id', to: 'shelters#delete'
  end

  scope '/friendship' do
    post '/add', to: 'friendship#add'
    post '/reply', to: 'friendship#reply'
    delete '/remove', to: 'friendship#remove'
    get '/received_invitations', to: 'friendship#received_invitations'
  end

  scope 'membership' do
    get '/invited', to: 'membership#invited'
    get '/waiting', to: 'membership#waiting'

    post '/join', to: 'membership#join_assoc'
    post '/reply_member', to: 'membership#reply_member'
    post '/invite', to: 'membership#invite'
    post '/reply_invite', to: 'membership#reply_invite'

    put '/upgrade', to: 'membership#upgrade'

    delete '/kick', to: 'membership#kick'
    delete '/leave', to: 'membership#leave_assoc'
    delete '/uninvite', to: 'membership#uninvite'
  end

  scope '/volunteers' do
    get '/', to: 'volunteers#index'
    get '/:id', to: 'volunteers#show'
    get '/:id/friends', to: 'volunteers#friends'
    get '/:id/associations', to: 'volunteers#associations'
    get '/:id/events', to: 'volunteers#events'
    get '/:id/pictures', to: 'volunteers#pictures'
    get '/:id/main_picture', to: 'volunteers#main_picture'
    get '/:id/news', to: 'volunteers#news'

    post '/', to: 'volunteers#create'

    put '/', to: 'volunteers#update' 

    delete '/:id', to: 'volunteers#destroy'
    match '/', to: 'doc#index', via: :all
  end

  scope '/associations' do
    get '/', to: 'assocs#index'
    get '/invited', to: 'assocs#invited'
    get '/:id', to: 'assocs#show'
    get '/:id/members', to: 'assocs#members'
    get '/:id/notifications', to: 'assocs#notifications'
    get '/:id/events', to: 'assocs#events'
    get '/:id/pictures', to: 'assocs#pictures'
    get '/:id/main_picture', to: 'assocs#main_picture'
    get '/:id/news', to: 'assocs#news'

    post '/', to: 'assocs#create'

    put '/:id', to: 'assocs#update' 

    delete '/:id', to: 'assocs#delete'
    match '/', to: 'doc#index', via: :all
  end

  scope '/events' do
    get '/', to: 'events#index'
    get '/owned', to: 'events#owned'
    get '/invited', to: 'events#invited'
    get '/:id', to: 'events#show'
    get '/:id/guests', to: 'events#guests'
    get '/:id/notifications', to: 'events#notifications'
    get '/:id/pictures', to: 'events#pictures'
    get '/:id/main_picture', to: 'events#main_picture'
    get '/:id/news', to: 'events#news'
    
    post '/', to: 'events#create'

    put '/:id', to: 'events#update'

    delete '/:id', to: 'events#delete'
  end

  scope '/guests' do
    get '/invited', to: 'guests#invited'
    get '/waiting', to: 'guests#waiting'
    
    post '/join', to: 'guests#join'
    post '/reply_guest', to: 'guests#reply_guest'
    post '/invite', to: 'guests#invite'
    post '/reply_invite', to: 'guests#reply_invite'

    put '/upgrade', to: 'guests#upgrade'

    delete '/kick', to: 'guests#kick'    
    delete '/leave', to: 'guests#leave_event'
    delete '/uninvite', to: 'guests#uninvite'
  end

  scope '/chatrooms' do
    post '/', to: 'messages#create'

    get '/', to: 'messages#index'
    get '/:id', to: 'messages#show'
    get '/:id/volunteers', to: 'messages#participants'

    put '/:id/set_name', to: 'messages#set_name'
    put '/:id/add_volunteers', to: 'messages#add_volunteers'
    put '/:id/new_message', to: 'messages#new_message'

    delete '/', to: 'messages#reset' # a supprimer
    delete '/:id/kick', to: 'messages#kick_volunteer'
    delete '/:id/leave', to: 'messages#leave'
    delete '/:id/delete_message', to: 'messages#delete_message'
  end

  scope '/pictures' do
    post '/', to: 'pictures#create'

    put '/:id', to: 'pictures#update'

    delete '/:id', to: 'pictures#delete'
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

  match '*path', to: 'doc#index', via: :all

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
