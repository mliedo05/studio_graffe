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

  # ── brands ────────────────────────────────────────────────────────

  test "brands devuelve solo marcas de productos activos" do
    brands = ShopService.brands
    assert_includes     brands, "Wella"
    assert_includes     brands, "Olaplex"
    assert_not_includes brands, "OldBrand", "no debe incluir marcas de productos inactivos"
  end

  test "brands devuelve marcas ordenadas alfabéticamente" do
    brands = ShopService.brands
    assert_equal brands, brands.sort
  end

  test "brands no devuelve duplicados" do
    brands = ShopService.brands
    assert_equal brands.uniq, brands
  end

  test "brand_slug convierte nombre a slug URL-safe" do
    assert_equal "wella",   ShopService.brand_slug("Wella")
    assert_equal "olaplex", ShopService.brand_slug("Olaplex")
  end

  test "brand_from_slug devuelve el nombre original de la marca" do
    assert_equal "Wella",   ShopService.brand_from_slug("wella")
    assert_equal "Olaplex", ShopService.brand_from_slug("olaplex")
  end

  test "brand_from_slug devuelve nil para slug inexistente" do
    assert_nil ShopService.brand_from_slug("no-existe")
  end

  # ── brand_data ────────────────────────────────────────────────────

  test "brand_data devuelve el nombre de marca correcto" do
    data = ShopService.brand_data(brand_slug: "wella", pagy_helper: method(:pagy_stub))
    assert_equal "Wella", data[:brand]
  end

  test "brand_data devuelve solo productos activos de esa marca" do
    data = ShopService.brand_data(brand_slug: "wella", pagy_helper: method(:pagy_stub))
    assert data[:products].any?, "debe haber productos de Wella"
    assert data[:products].all? { |p| p.brand == "Wella" },
      "todos los productos deben ser de Wella"
  end

  test "brand_data no incluye productos inactivos" do
    data = ShopService.brand_data(brand_slug: "wella", pagy_helper: method(:pagy_stub))
    assert data[:products].all?(&:active?)
  end

  test "brand_data devuelve categorías y marcas para el sidebar" do
    data = ShopService.brand_data(brand_slug: "wella", pagy_helper: method(:pagy_stub))
    assert_not_nil data[:categories]
    assert_not_nil data[:brands]
  end

  test "brand_data lanza RecordNotFound para slug inexistente" do
    assert_raises(ActiveRecord::RecordNotFound) do
      ShopService.brand_data(brand_slug: "no-existe", pagy_helper: method(:pagy_stub))
    end
  end

  test "index_data devuelve lista de marcas" do
    data = ShopService.index_data(pagy_helper: method(:pagy_stub))
    assert_not_nil data[:brands]
    assert_includes data[:brands], "Wella"
  end

  test "category_data devuelve lista de marcas para el sidebar" do
    data = ShopService.category_data(
      slug: product_categories(:shampoo).slug,
      pagy_helper: method(:pagy_stub)
    )
    assert_not_nil data[:brands]
  end
end
