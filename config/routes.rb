require 'sidekiq/web'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount Sidekiq::Web => '/sidekiq'
  Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
    [user, password] == [ENV["SIDEKIQ_USERNAME"], ENV["SIDEKIQ_PASSWORD"]]
  end

  # Default route for root url
	get '/', to: 'home#index'
	post '/', to: 'home#index'

# Route to login admin dashboard with specisic app_id
  get '/admin', to: 'dashboard/admin/auth#index'
  get '/admin/:app_id', to: 'dashboard/admin/auth#index'
  get '/admin/:app_id/auth_phone_number', to: 'dashboard/admin/auth#index'
  get '/admin/:app_id/auth_email', to: 'dashboard/admin/auth_email#index'

  # Route to login user dashboard with specific app_id
  get 'app/', to: 'dashboard/user/auth#index'
  get 'app/:app_id', to: 'dashboard/user/auth#index'

  # Route to login super admin dashboard
  get '/superadmin', to: 'dashboard/auth#index'

  namespace :dashboard, path: '/dashboard' do
    resources :auth, only: [:index, :create] do
      get :logout, on: :collection
    end

    namespace :admin, path: '/admin' do
      resources :auth, only: [:index, :create] do
        get :logout, on: :collection
      end

      resources :auth_email, only: [:index, :create]

      resources :home, only: [:index] do
        post :make_all_users_as_contact, on: :collection
      end
      resources :users, only: [:index, :show, :new, :create] do
        # get '/delete', to: 'users#delete', on: :member
        get :delete, on: :member
        get '/activity', to: 'users#activity'
        get '/list_sessions', to: 'users#list_sessions', on: :collection
        post :update_features, on: :member
        post :create_room_with_unique_id, on: :member
        get :export, on: :collection
        get :export_list_sessions, on: :collection
				post :post_export, on: :collection
        post :update
        resources :auth_sessions, only: [:create] do
          get '/delete', to: 'auth_sessions#delete', on: :member
          get '/delete_all', to: 'auth_sessions#delete_all', on: :collection
        end
      end
      resources :mobile_versions, only: [:index] do
        post '/create_or_update', to: 'mobile_versions#create_or_update', on: :member
      end
      resources :announcements, only: [:new, :index, :show, :create] do
        post :update
        get '/delete', to: 'announcements#delete', on: :member
      end
      resources :features, only: [:new, :index, :show, :create] do
        post :update
        get '/delete', to: 'features#delete', on: :member
      end
      resources :feature_flag, only: [:index, :create, :show] do
        get 'show_users', to: 'feature_flag#show_users', on: :collection
        get 'delete', to: 'feature_flag#delete', on: :member
      end

      resources :user_dedicated_passcodes, only: [:new, :index, :show, :create] do
        post :update
        get '/delete', to: 'user_dedicated_passcodes#delete', on: :member
      end

      resources :broadcasts, only: [:index, :create, :show] do
        get 'show_chat_users', to: 'broadcasts#show_chat_users', on: :collection
        post 'show_users', to: 'broadcasts#show_users', on: :collection
        get 'show_status', to: 'broadcasts#show_status', on: :collection
        get 'show_receipt_histories', to: 'broadcasts#show_receipt_histories', on: :collection
      end
    end

    namespace :super_admin, path: '/super_admin' do
      resources :application, only: [:index, :show, :new, :create, :edit] do
        post :update, on: :member
        get '/delete', to: 'application#delete', on: :member
        get '/mobile_version', to: 'application#mobile_version', on: :member
        post '/mobile_version', to: 'application#mobile_version_update', on: :member
        get '/provider_setting', to: 'application#provider_setting', on: :member
        post '/provider_setting', to: 'application#provider_setting_update', on: :member
        post :make_all_users_as_contact, on: :member
      end

      namespace :application, path: '/application/:application_id' do
        resources :users, only: [:new, :index, :show, :create] do
          get '/delete', to: 'users#delete', on: :member
          get '/activity', to: 'users#activity', on: :member
          get '/list_sessions', to: 'users#list_sessions', on: :collection
          post :update_features, on: :member
          post :update_custom_menus, on: :member
          post :create_room_with_unique_id, on: :member
          get :export, on: :collection
          get :export_list_sessions, on: :collection
          post :post_export, on: :collection
          post :update, on: :member

          resources :auth_sessions, only: [:create] do
            get '/delete', to: 'auth_sessions#delete', on: :member
            get '/delete_all', to: 'auth_sessions#delete_all', on: :collection
          end
        end

        resources :announcements, only: [:new, :index, :show, :create] do
          post :update
          get '/delete', to: 'announcements#delete', on: :member
        end

        resources :user_dedicated_passcodes, only: [:new, :index, :show, :create] do
          post :update
          get '/delete', to: 'user_dedicated_passcodes#delete', on: :member
        end

        resources :features, only: [:new, :index, :show, :create] do
          post :update
          get '/delete', to: 'features#delete', on: :member
        end

        resources :feature_flag, only: [:index, :create, :show] do
          get 'show_users', to: 'feature_flag#show_users', on: :collection
          get 'delete', to: 'feature_flag#delete', on: :member
        end

        resources :custom_menus, only: [:new, :index, :show, :create] do
          post :update
          get '/delete', to: 'custom_menus#delete', on: :member
        end

        resources :broadcasts, only: [:index, :create, :show] do
          get 'show_chat_users', to: 'broadcasts#show_chat_users', on: :collection
          post 'show_users', to: 'broadcasts#show_users', on: :collection
          get 'show_status', to: 'broadcasts#show_status', on: :collection
          get 'show_receipt_histories', to: 'broadcasts#show_receipt_histories', on: :collection
        end
      end

      resources :home, only: [:index]
    end

    namespace :user, path: '/user' do
      resources :auth, only: [:index, :create] do
        get :logout, on: :collection
      end

      resources :home, only: [:index]
      resources :profile, only: [:index] do
        post :update
        get '/activity', to: 'profile#activity', on: :collection
        resources :auth_sessions, only: [:create] do
          get '/delete', to: 'auth_sessions#delete', on: :member
          get '/delete_all', to: 'auth_sessions#delete_all', on: :collection
        end
      end
    end
  end

  namespace :api, path: '/api' do
    scope defaults: { format: 'json' } do

      # API version 1 Scope
      scope module: :v1, path: '/v1' do

        scope module: :admin, path: '/admin' do
          resources :auth, only: [:create] do
            post :resend_passcode, on: :collection
            post :verify, on: :collection
          end

          resources :auth_email, only: [:create] do
            post :resend_passcode, on: :collection
            post :verify, on: :collection
          end

          resources :applications do
            get :users, on: :member
          end

          resources :chat_rooms, only: [:index, :create, :show] do
            post :group_chat, on: :collection
            post :change_group_name, on: :member
            post :import_group_chat, on: :collection
            post :delete_all_participants, on: :collection
          end

          scope module: :chat_rooms, path: '/chat_rooms/:chatroom_id' do
            post '/delete_participants', to: 'participants#delete_participants'

            resources :participants, only: [:index, :create] do
              delete '/', to: 'participants#delete_participants', on: :collection
            end
          end

          resources :roles, only: [:index]

          resources :statistics, only: [:index]

          resources :users do
            get :contacts, on: :member
            get :import_template, on: :collection
            get :chat_rooms, on: :member
            post :import, on: :collection
            get :all, on: :collection
            get :officials, on: :collection
            get :officials_all, on: :collection
            post :update_avatar, on: :member
            post :send_message, on: :collection
          end

          resources :calls, only: [:index]

          scope module: :users, path: '/users/:user_id' do
            resources :roles, only: [:index, :create] do
              delete '/', to: 'roles#destroy_roles', on: :collection
            end

            resources :sessions, only: [:index, :destroy]
            delete '/flush_sessions', to: 'sessions#flush'
          end

          scope module: :utilities, path: '/utilities' do
            resources :mobile_apps_version, only: [:index, :create]
          end

          resources :contacts, only: [:index, :create] do
            delete '/', to: 'contacts#destroy_contacts', on: :collection
          end
        end

        scope module: :chat, path: '/chat' do

          # above all, to avoid error because it's like /conversations/:id using method ConversationsController#show
          scope module: :conversations, path: '/conversations' do
            resources :group_chat, only: [:index]
            resources :pin_chats, only: [:index, :create] do
              delete '/', to: 'pin_chats#destroy_pin_chats', on: :collection
            end
            resources :mute_chats, only: [:create] do
              delete '/', to: 'mute_chats#destroy_mute_chats', on: :collection
            end
          end

          resources :conversations, only: [:index, :create, :show] do
            post :group_chat, on: :collection
            post :channel, on: :collection
            post :change_group_name, on: :collection
            post :change_group_avatar, on: :collection
            post :post_comment, on: :collection
            get :load_comments, on: :collection
            get :get_room_by_id, on: :collection
            get :sync, on: :collection
            get :new_index, on: :collection
            get :filter, on: :collection
            post :join_room_with_unique_id, on: :collection
            get :rooms, on: :collection
						post :post_system_event_message, on: :collection
          end

          scope module: :conversations, path: '/conversations/:chatroom_id' do
            post '/delete_participants', to: 'participants#delete_participants'
            post '/leave_group', to: 'participants#leave_group'

            resources :participants, only: [:index, :create] do
              delete '/', to: 'participants#delete_participants', on: :collection
            end

            resources :admins, only: [:index, :create] do
              delete '/', to: 'admins#delete_group_admins', on: :collection
            end
          end

          resources :broadcast, only: [:create]
        end

        resources :auth, only: [:create] do
          post :resend_passcode, on: :collection
          post :verify, on: :collection
        end

        resources :auth_email, only: [:create] do
          post :resend_passcode, on: :collection
          post :verify, on: :collection
        end

        resources :auth_nonce, only: [:create] do
          post :verify, on: :collection
          post :resend_passcode, on: :collection
        end

        resources :auth_email_nonce, only: [:create] do
          post :resend_passcode, on: :collection
          post :verify, on: :collection
        end

        resources :contacts, only: [:index, :create] do
          delete :delete_contact, on: :collection
          post :search, on: :collection
          post :search_by_qiscus_email, on: :collection
          post :search_by_email, on: :collection
          post :search_by_all_field, on: :collection
          post :search_bot, on: :collection
          post :bot, on: :collection
        end

        scope module: :contacts, path: '/contacts' do
          resources :favorites, only: [:index, :show, :create, :destroy]
          resources :officials, only: [:index]
          resources :sync, only: [:create]
        end

        resources :me, only: [:index] do
          post :update_profile, on: :collection
          patch :update_profile, on: :collection
          put :update_profile, on: :collection

          post :update_avatar, on: :collection
          get '/contacts', to: 'contacts#index', on: :collection

          get :features, on: :collection

          post :register_device_token, on: :collection
          post :delete_device_token, on: :collection

          post :identity_token, on: :collection
          post :logout, on: :collection
        end

        scope module: :me, path: '/me' do
          resources :sessions, only: [:index, :destroy]
          resources :posts, only: [:index, :destroy]
        end

        scope module: :files, path: '/files' do
          resources :uploader, only: [:create]
        end

        scope module: :listeners, path: '/listeners' do
          resources :telkom_news_bot_production, only: [:create]
          resources :telkom_news_bot_staging, only: [:create]
        end

        scope module: :utilities, path: '/utilities' do
          resources :mobile_apps_version, only: [:index]
        end

        scope module: :webhooks, path: '/webhooks' do
          post '/bot-callback/:app_id', to: 'bot_callback#create'
          resources :bot_builder, only: [] do
            post :handler, on: :collection
          end
        end

        resources :posts, only: [:index, :create, :destroy, :show, :update]

        scope module: :posts, path: '/posts/:post_id' do
          resources :comments, only: [:index, :create, :destroy]
          resources :likes, only: [:index, :create] do
            delete '/', to: 'likes#destroy', on: :collection
          end
        end

        scope module: :posts, path: '/posts/' do
          resources :users, only: [:show]
        end

        resources :announcements, only: [:index] do
          get :last, on: :collection
        end

        resources :calls, only: [:create, :index]

        scope module: :rest, path: '/rest/' do
          resources :auth_email, only: [:create]
          resources :auth_email_nonce, only: [:create]
          resources :conversations, only: [] do
            post :create_room_with_unique_id, on: :collection
            post :create_or_join_room_with_unique_id, on: :collection
            post :post_system_event_message, on: :collection
          end
          resources :me, only: [] do
            post :update_profile, on: :collection
          end
        end

        resources :push_notifications, only: [:create]

        resources :passcode, only: [:create] do
          post :verify, on: :collection
        end

        resources :users, only: [:index, :show]
      end
      scope module: :v2, path: '/v2' do
        resources :channel, only: [:show] do
          get :username_to_room_id, on: :collection
        end
        scope module: :contacts, path: '/contacts' do
          resources :sync, only: [:create]
        end
      end
    end
  end
end
