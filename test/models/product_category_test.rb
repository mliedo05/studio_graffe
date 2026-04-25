require "test_helper"

class ProductCategoryTest < ActiveSupport::TestCase
  test "válido con atributos correctos" do
    cat = ProductCategory.new(name: "Nueva Categoría", slug: "nueva-categoria")
    assert cat.valid?
  end

  test "inválido sin name" do
    cat = product_categories(:shampoo)
    cat.name = nil
    assert_not cat.valid?
  end

  test "inválido con slug duplicado" do
    cat = ProductCategory.new(name: "Otro", slug: product_categories(:shampoo).slug)
    assert_not cat.valid?
    assert_includes cat.errors[:slug], "has already been taken"
  end

  test "inválido con slug con caracteres inválidos" do
    cat = ProductCategory.new(name: "Test", slug: "Mi Categoría!")
    assert_not cat.valid?
  end

  test "genera slug desde name automáticamente" do
    cat = ProductCategory.create!(name: "Coloración Premium")
    assert_equal "coloracion-premium", cat.slug
  end

  test "scope active excluye inactivas" do
    assert_includes ProductCategory.active, product_categories(:shampoo)
    assert_not_includes ProductCategory.active, product_categories(:inactiva)
  end
end
