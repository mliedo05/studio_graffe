class ShopService
  DEFAULT_PER_PAGE = 12

  def self.brands
    Product.active.for_sale.distinct.order(:brand).pluck(:brand).compact
  end

  def self.brand_slug(brand)
    brand.parameterize
  end

  def self.brand_from_slug(slug)
    brands.find { |b| brand_slug(b) == slug }
  end

  def self.index_data(pagy_helper:, params: {})
    categories = ProductCategory.active.ordered
    featured   = Product.active.for_sale.featured.includes(:product_category).limit(8)
    pagy, products = pagy_helper.call(
      Product.active.for_sale.includes(:product_category).ordered,
      items: DEFAULT_PER_PAGE
    )
    { categories: categories, brands: brands, featured: featured, pagy: pagy, products: products }
  end

  def self.brand_data(brand_slug:, pagy_helper:)
    brand = brand_from_slug(brand_slug)
    raise ActiveRecord::RecordNotFound if brand.nil?

    pagy, products = pagy_helper.call(
      Product.active.for_sale.where(brand: brand).includes(:product_category).ordered,
      items: DEFAULT_PER_PAGE
    )
    { brand: brand, brands: brands, categories: ProductCategory.active.ordered,
      pagy: pagy, products: products }
  end

  def self.category_data(slug:, pagy_helper:)
    category = ProductCategory.active.find_by!(slug: slug)
    pagy, products = pagy_helper.call(category.products.active.for_sale.ordered, items: DEFAULT_PER_PAGE)
    { category: category, brands: brands, categories: ProductCategory.active.ordered,
      pagy: pagy, products: products }
  end

  def self.product_data(category_slug:, product_slug:)
    category = ProductCategory.active.find_by!(slug: category_slug)
    product  = category.products.active.for_sale.find_by!(slug: product_slug)
    related  = category.products.active.for_sale.where.not(id: product.id).limit(4)
    { category: category, product: product, related: related }
  end
end
