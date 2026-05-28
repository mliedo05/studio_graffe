require "test_helper"

class ShopServiceTest < ActiveSupport::TestCase
  # Pagy helper stub para tests unitarios (sin contexto de request)
  def pagy_stub(scope, items: 12)
    pagy   = Pagy.new(count: scope.count, page: 1, items: items)
    result = scope.limit(items).offset(0)
    [ pagy, result ]
  end

  # index_data
  test "index_data devuelve categorías activas" do
    data = ShopService.index_data(pagy_helper: method(:pagy_stub))
    assert_includes data[:categories], product_categories(:shampoo)
    assert_not_includes data[:categories], product_categories(:inactiva)
  end

  test "index_data devuelve productos destacados" do
    data = ShopService.index_data(pagy_helper: method(:pagy_stub))
    assert data[:featured].all?(&:featured?)
  end

  test "index_data devuelve pagy y products paginados" do
    data = ShopService.index_data(pagy_helper: method(:pagy_stub))
    assert_not_nil data[:pagy]
    assert_not_nil data[:products]
  end

  # category_data
  test "category_data devuelve la categoría por slug" do
    data = ShopService.category_data(
      slug: product_categories(:shampoo).slug,
      pagy_helper: method(:pagy_stub)
    )
    assert_equal product_categories(:shampoo), data[:category]
  end

  test "category_data devuelve solo productos de esa categoría" do
    data = ShopService.category_data(
      slug: product_categories(:shampoo).slug,
      pagy_helper: method(:pagy_stub)
    )
    assert data[:products].all? { |p| p.product_category_id == product_categories(:shampoo).id }
  end

  test "category_data lanza RecordNotFound para slug inexistente" do
    assert_raises(ActiveRecord::RecordNotFound) do
      ShopService.category_data(slug: "no-existe", pagy_helper: method(:pagy_stub))
    end
  end

  # product_data
  test "product_data devuelve categoría, producto y relacionados" do
    product  = products(:shampoo_wella)
    category = product_categories(:shampoo)

    data = ShopService.product_data(
      category_slug: category.slug,
      product_slug:  product.slug
    )

    assert_equal category, data[:category]
    assert_equal product,  data[:product]
    assert data[:related].none? { |p| p.id == product.id }
  end

  test "product_data lanza RecordNotFound para producto inexistente" do
    assert_raises(ActiveRecord::RecordNotFound) do
      ShopService.product_data(
        category_slug: product_categories(:shampoo).slug,
        product_slug:  "no-existe"
      )
    end
  end

  test "product_data lanza RecordNotFound para categoría inexistente" do
    assert_raises(ActiveRecord::RecordNotFound) do
      ShopService.product_data(
        category_slug: "no-existe",
        product_slug:  products(:shampoo_wella).slug
      )
    end
  end
end
