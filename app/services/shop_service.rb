class ShopService
  DEFAULT_PER_PAGE = 12

  def self.index_data(pagy_helper:, params: {})
    categories = ProductCategory.active.ordered
    featured   = Product.active.featured.includes(:product_category).limit(8)
    pagy, products = pagy_helper.call(
      Product.active.includes(:product_category).ordered,
      items: DEFAULT_PER_PAGE
    )
    { categories: categories, featured: featured, pagy: pagy, products: products }
  end

  def self.category_data(slug:, pagy_helper:)
    category = ProductCategory.active.find_by!(slug: slug)
    pagy, products = pagy_helper.call(category.products.active.ordered, items: DEFAULT_PER_PAGE)
    { category: category, pagy: pagy, products: products }
  end

  def self.product_data(category_slug:, product_slug:)
    category = ProductCategory.active.find_by!(slug: category_slug)
    product  = category.products.active.find_by!(slug: product_slug)
    related  = category.products.active.where.not(id: product.id).limit(4)
    { category: category, product: product, related: related }
  end
end
