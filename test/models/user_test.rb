require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Validaciones
  test "válido con atributos correctos" do
    user = User.new(
      first_name: "Juan",
      last_name: "Pérez",
      email: "juan@example.com",
      password: "password123",
      role: "client"
    )
    assert user.valid?
  end

  test "inválido sin first_name" do
    user = users(:cliente)
    user.first_name = nil
    assert_not user.valid?
    assert_includes user.errors[:first_name], "can't be blank"
  end

  test "inválido sin last_name" do
    user = users(:cliente)
    user.last_name = nil
    assert_not user.valid?
  end

  test "inválido con role desconocido" do
    user = users(:cliente)
    user.role = "superadmin"
    assert_not user.valid?
  end

  test "inválido con email duplicado" do
    user = User.new(
      first_name: "Otro",
      last_name: "Usuario",
      email: users(:cliente).email,
      password: "password123",
      role: "client"
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  # Métodos de rol
  test "admin? devuelve true para admin" do
    assert users(:admin).admin?
  end

  test "admin? devuelve false para cliente" do
    assert_not users(:cliente).admin?
  end

  test "stylist? devuelve true para estilista" do
    assert users(:valentina).stylist?
  end

  test "client? devuelve true para cliente" do
    assert users(:cliente).client?
  end

  # full_name
  test "full_name combina nombre y apellido" do
    user = users(:valentina)
    assert_equal "Valentina Rojas", user.full_name
  end

  # Scopes
  test "scope admins filtra solo administradores" do
    assert_includes User.admins, users(:admin)
    assert_not_includes User.admins, users(:cliente)
  end

  test "scope stylists filtra solo estilistas" do
    assert_includes User.stylists, users(:valentina)
    assert_not_includes User.stylists, users(:admin)
  end

  test "scope clients filtra solo clientes" do
    assert_includes User.clients, users(:cliente)
    assert_not_includes User.clients, users(:valentina)
  end

  # current_cart
  test "current_cart crea un carrito si no existe" do
    user = users(:cliente)
    cart = user.current_cart
    assert_equal "cart", cart.status
    assert_equal user, cart.user
  end

  test "current_cart devuelve el mismo carrito existente" do
    user = users(:cliente)
    first_cart  = user.current_cart
    second_cart = user.current_cart
    assert_equal first_cart.id, second_cart.id
  end

  # Asociaciones
  test "tiene stylist_profile" do
    assert_respond_to users(:valentina), :stylist_profile
    assert_not_nil users(:valentina).stylist_profile
  end

  test "tiene stylist_schedules" do
    assert_respond_to users(:valentina), :stylist_schedules
  end
end
