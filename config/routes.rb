Rails.application.routes.draw do
  ActiveAdmin.routes(self)

  devise_for :users, path: "cuenta", path_names: {
    sign_in:  "ingresar",
    sign_out: "salir",
    sign_up:  "registro"
  }, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  # Tienda
  get  "/tienda",                                    to: "shop#index",    as: :shop
  get  "/tienda/marca/:brand_slug",                  to: "shop#brand",    as: :shop_brand
  get  "/tienda/:category_slug",                     to: "shop#category", as: :shop_category
  get  "/tienda/:category_slug/:product_slug",       to: "shop#show",     as: :shop_product

  # Carrito
  get     "/carrito",                                to: "cart#show",         as: :cart
  get     "/carrito/datos",                          to: "cart#drawer_data",  as: :cart_drawer_data
  delete  "/carrito/vaciar",                         to: "cart#clear",        as: :cart_clear
  post    "/carrito/agregar",                        to: "cart_items#create", as: :cart_add_item
  delete  "/carrito/items/:id",                      to: "cart_items#destroy", as: :cart_item
  patch   "/carrito/items/:id",                      to: "cart_items#update",  as: :update_cart_item

  # Checkout
  get   "/checkout",       to: "checkout#show",    as: :checkout
  patch "/checkout",       to: "checkout#update",  as: :checkout_update
  post  "/checkout/pago",  to: "checkout#payment", as: :checkout_payment

  # Getnet Web Checkout callbacks
  get  "/getnet/retorno",       to: "getnet#return_payment", as: :getnet_return
  post "/getnet/notificacion",  to: "getnet#notification",   as: :getnet_notification

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

  # Direcciones guardadas
  resources :addresses, path: "direcciones", only: [ :create, :update, :destroy ] do
    member { patch :set_default }
  end

  # ── Panel Supervisor ──────────────────────────────────────────────
  namespace :supervisor do
    root to: "dashboard#index"
    resources :attendances, only: [ :index, :new, :create, :show, :edit, :update ] do
      member { patch :close }
      collection { get :search_client }
    end
    get "/comisiones",          to: "commissions#index",   as: :commissions
    get "/comisiones/exportar", to: "commissions#export",  as: :commissions_export
    get "/ventas",              to: "sales#index",         as: :sales
  end

  # ── Panel Estilista ───────────────────────────────────────────────
  namespace :stylist_panel, path: "mi-panel" do
    root to: "dashboard#index"
    get "/comisiones", to: "commissions#index", as: :commissions
  end

  get "/inicio", to: "shop#landing", as: :landing
  root to: "shop#landing"
end
