class ShopController < ApplicationController
  include Pagy::Backend

  def landing
    @featured_services  = Service.active.ordered.limit(4)
    @featured_products  = Product.active.where(featured: true).limit(6)
    @stylists           = User.stylists.limit(3)
    @instagram_posts    = InstagramService.fetch_posts(limit: 9)
    Rails.logger.info "[Landing] Instagram posts loaded: #{@instagram_posts.count}"
  end

  def index
    data = ShopService.index_data(pagy_helper: method(:pagy))
    @categories            = data[:categories]
    @brands                = data[:brands]
    @featured              = data[:featured]
    @pagy                  = data[:pagy]
    @products              = data[:products]
    @cart_items_by_product = cart_items_by_product
  end

  def category
    data = ShopService.category_data(slug: params[:category_slug], pagy_helper: method(:pagy))
    @category              = data[:category]
    @categories            = data[:categories]
    @brands                = data[:brands]
    @pagy                  = data[:pagy]
    @products              = data[:products]
    @cart_items_by_product = cart_items_by_product
  end

  def brand
    data = ShopService.brand_data(brand_slug: params[:brand_slug], pagy_helper: method(:pagy))
    @brand                 = data[:brand]
    @categories            = data[:categories]
    @brands                = data[:brands]
    @pagy                  = data[:pagy]
    @products              = data[:products]
    @cart_items_by_product = cart_items_by_product
  rescue ActiveRecord::RecordNotFound
    redirect_to shop_path, alert: "Marca no encontrada."
  end

  def show
    data = ShopService.product_data(
      category_slug: params[:category_slug],
      product_slug:  params[:product_slug]
    )
    @category  = data[:category]
    @product   = data[:product]
    @related   = data[:related]
    @cart_item = cart_items_by_product[@product.id]
  end

  private

  def cart_items_by_product
    return {} unless user_signed_in?

    CartService.cart_for(current_user).order_items.index_by(&:product_id)
  end
end
