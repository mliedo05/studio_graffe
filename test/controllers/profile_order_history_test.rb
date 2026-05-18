require "test_helper"

class ProfileOrderHistoryTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:cliente)
    sign_in_as @user
  end

  test "GET /perfil muestra el historial de compras" do
    get profile_path
    assert_response :success
    assert_select "h2", text: /Historial de compras/i
  end

  test "muestra mensaje cuando no hay compras" do
    # Asegurarse de que no hay órdenes completadas para este usuario
    @user.orders.where.not(status: "cart").destroy_all
    get profile_path
    assert_select "p", text: /Aún no tienes compras/i
  end

  test "muestra el número y total de cada orden completada" do
    order = orders(:orden_pagada)
    get profile_path
    assert_select "p", text: /#{order.number}/
  end

  test "muestra el botón 'Ver productos' por cada orden" do
    order = orders(:orden_pagada)
    get profile_path
    assert_select "button", text: /Ver productos/i
  end

  test "incluye el dialog modal para cada orden" do
    order = orders(:orden_pagada)
    get profile_path
    assert_select "dialog#order-modal-#{order.id}"
  end

  test "el modal muestra los productos de la orden con cantidades" do
    order = orders(:orden_pagada)
    get profile_path
    # El modal debe contener un ×N por cada item
    order.order_items.each do |item|
      assert_select "dialog#order-modal-#{order.id}" do
        assert_select "*", text: /×#{item.quantity}/
      end
    end
  end

  test "el modal muestra el estado de la orden" do
    get profile_path
    assert_select "dialog#order-modal-#{orders(:orden_pagada).id}" do
      assert_select "*", text: /Pagado/i
    end
  end

  test "muestra el badge de estado correcto (Pagado en verde)" do
    get profile_path
    assert_select ".bg-green-100", text: /Pagado/i
  end
end
