require "test_helper"

class AdminAccessTest < ActionDispatch::IntegrationTest
  test "usuario no autenticado es redirigido a login al acceder a /admin" do
    get admin_root_path
    assert_redirected_to new_user_session_path
  end

  test "usuario cliente es redirigido a login al intentar acceder a /admin" do
    sign_in_as(users(:cliente))
    get admin_root_path
    assert_redirected_to new_user_session_path
    assert_match "administrador", flash[:alert]
  end

  test "usuario stylist es redirigido a login al intentar acceder a /admin" do
    sign_in_as(users(:valentina))
    get admin_root_path
    assert_redirected_to new_user_session_path
  end

  test "usuario admin puede acceder a /admin" do
    sign_in_as(users(:admin))
    get admin_root_path
    assert_response :success
  end
end
