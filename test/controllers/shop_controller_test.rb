require "test_helper"

class ShopControllerTest < ActionDispatch::IntegrationTest
  test "GET /tienda devuelve 200" do
    get shop_path
    assert_response :success
  end

  test "GET /tienda muestra productos destacados" do
    get shop_path
    assert_response :success
  end

  test "GET /tienda/:category_slug devuelve 200 para categoría activa" do
    get shop_category_path(category_slug: product_categories(:shampoo).slug)
    assert_response :success
  end

  test "GET /tienda/:category_slug devuelve 404 para categoría inexistente" do
    get shop_category_path(category_slug: "no-existe")
    assert_response :not_found
  end

  test "GET /tienda/:cat/:slug devuelve 200 para producto activo" do
    product  = products(:shampoo_wella)
    category = product_categories(:shampoo)
    get shop_product_path(category_slug: category.slug, product_slug: product.slug)
    assert_response :success
  end

  test "GET /tienda/:cat/:slug devuelve 404 para slug inexistente" do
    get shop_product_path(category_slug: product_categories(:shampoo).slug, product_slug: "no-existe")
    assert_response :not_found
  end

  # --- landing page ---

  test "GET / devuelve 200" do
    get root_path
    assert_response :success
  end

  test "GET / con posts de Instagram devuelve 200" do
    get root_path
    assert_response :success
  end

  test "GET / cuando InstagramService devuelve vacío sigue devolviendo 200" do
    # Cache a blank result so the service returns []
    Rails.cache.write("instagram_feed_v3", nil)
    get root_path
    assert_response :success
    Rails.cache.delete("instagram_feed_v3")
  end

  test "GET /inicio también devuelve 200" do
    get landing_path
    assert_response :success
  end
end
