require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "válido con atributos correctos" do
    product = Product.new(
      name: "Nuevo Shampoo",
      brand: "TestBrand",
      price_cents: 10000,
      stock_quantity: 5,
      product_category: product_categories(:shampoo)
    )
    assert product.valid?
  end

  test "inválido sin name" do
    products(:shampoo_wella).tap { |p| p.name = nil; assert_not p.valid? }
  end

  test "inválido sin brand" do
    products(:shampoo_wella).tap { |p| p.brand = nil; assert_not p.valid? }
  end

  test "inválido con price_cents negativo" do
    products(:shampoo_wella).tap { |p| p.price_cents = -100; assert_not p.valid? }
  end

  test "inválido con stock_quantity negativo" do
    products(:shampoo_wella).tap { |p| p.stock_quantity = -1; assert_not p.valid? }
  end

  test "inválido con nombre duplicado en la misma marca" do
    dup = Product.new(
      name:             products(:shampoo_wella).name,
      brand:            products(:shampoo_wella).brand,
      price_cents:      5000,
      stock_quantity:   1,
      product_category: product_categories(:shampoo)
    )
    assert_not dup.valid?
    assert dup.errors[:name].any?
  end

  test "permite el mismo nombre en distinta marca" do
    dup = Product.new(
      name:             products(:shampoo_wella).name,
      brand:            "OtraMarca",
      price_cents:      5000,
      stock_quantity:   1,
      product_category: product_categories(:shampoo)
    )
    assert dup.valid?
  end

  test "genera slug automáticamente" do
    product = Product.create!(
      name: "Mi Shampoo Especial", brand: "BrandTest",
      price_cents: 5000, stock_quantity: 1,
      product_category: product_categories(:shampoo)
    )
    assert_equal "brandtest-mi-shampoo-especial", product.slug
  end

  test "in_stock? devuelve true cuando hay stock" do
    assert products(:shampoo_wella).in_stock?
  end

  test "in_stock? devuelve false cuando no hay stock" do
    assert_not products(:olaplex).in_stock?
  end

  test "scope active excluye inactivos" do
    assert_includes     Product.active, products(:shampoo_wella)
    assert_not_includes Product.active, products(:producto_inactivo)
  end

  test "scope featured filtra destacados" do
    assert_includes     Product.featured, products(:shampoo_wella)
    assert_not_includes Product.featured, products(:acondicionador_wella)
  end

  test "scope in_stock filtra con stock > 0" do
    assert_includes     Product.in_stock, products(:shampoo_wella)
    assert_not_includes Product.in_stock, products(:olaplex)
  end
end
