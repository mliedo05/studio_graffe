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
    @categories = data[:categories]
    @featured   = data[:featured]
    @pagy       = data[:pagy]
    @products   = data[:products]
  end

  def category
    data = ShopService.category_data(slug: params[:category_slug], pagy_helper: method(:pagy))
    @category = data[:category]
    @pagy     = data[:pagy]
    @products = data[:products]
  end

  def show
    data = ShopService.product_data(
      category_slug: params[:category_slug],
      product_slug:  params[:product_slug]
    )
    @category = data[:category]
    @product  = data[:product]
    @related  = data[:related]
  end
end
