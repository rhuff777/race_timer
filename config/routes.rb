Rails.application.routes.draw do

  resources :penalties
	root 'home#index'
	resources :recipes, only: [:index]

  resources :races do
		member do
			post 'start_run'
			post 'finish_run'
			post 'next_heat'
			post 'clear_runs'
			post 'clear_racers'
			post 'check_for_more_runs'
			post 'sync_finish'
			post 'sync_finishes'
			post 'clear_unstarted_finishes'
			get 'start_run_form'
			get 'finish_run_form'
			put 'inline_update'
			get 'starts'
			get 'finishes'
			get 'results'
			get 'dashboard'
			get 'print_start_order'
			get 'racer_list'
			get 'score_strips'
			post 'authorize_finish'
		end
		collection do
			post 'save_all_racers'
			get 'racer_dashboard'
		end
  	resources :racers do 
			collection do
				get 'import'
				post 'do_import'
			end
		end
  	resources :runs
  	resources :penalties
	end

  resources :racers do
		member do
			put 'inline_update'
		end
		collection do
			get 'import'
			post 'do_import'
		end
	end

  resources :runs do
		member do
			post 'reheat'
			post 'dns'
			post 'dnf'
			put 'inline_update'
			put 'inline_update_racer'
			delete 'inline_destroy'
			post 'unfinish'
		end
			get 'starts'
			get 'finishes'
	end


  get "home/index"
  get "home/recipe"


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
