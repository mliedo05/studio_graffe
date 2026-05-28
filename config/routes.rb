Rails.application.routes.draw do
  ActiveAdmin.routes(self)

  devise_for :users, path: "cuenta", path_names: {
    sign_in:  "ingresar",
    sign_out: "salir",
    sign_up:  "registro"
  }

  # Tienda
  get  "/tienda",                                    to: "shop#index",    as: :shop
  get  "/tienda/:category_slug",                     to: "shop#category", as: :shop_category
  get  "/tienda/:category_slug/:product_slug",       to: "shop#show",     as: :shop_product

  # Carrito
  get     "/carrito",                                to: "cart#show",         as: :cart
  post    "/carrito/agregar",                        to: "cart_items#create", as: :cart_add_item
  delete  "/carrito/items/:id",                      to: "cart_items#destroy", as: :cart_item
  patch   "/carrito/items/:id",                      to: "cart_items#update",  as: :update_cart_item

  # Checkout
  get  "/checkout",                                  to: "checkout#show",    as: :checkout
  post "/checkout/pago",                             to: "checkout#payment", as: :checkout_payment

  # Citas
  resources :appointments, path: "citas", only: [ :index, :new, :create, :show ] do
    member { post :cancel }
  end

  # API interna de disponibilidad
  namespace :api do
    namespace :v1 do
      get "/disponibilidad", to: "availability#index", as: :availability
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Perfil de usuario
  get    "/perfil",        to: "profile#show",   as: :profile
  get    "/perfil/editar", to: "profile#edit",   as: :edit_profile
  patch  "/perfil",        to: "profile#update"

  get "/inicio", to: "shop#landing", as: :landing
  root to: "shop#landing"
end
