require "test_helper"

# Tests específicos para los campos de checkout añadidos a Order
class OrderCheckoutTest < ActiveSupport::TestCase
  def cart_with_product
    order = Order.create!(
      user:            users(:cliente),
      number:          "ORD-#{SecureRandom.hex(4).upcase}",
      status:          "cart",
      payment_status:  "pending",
      subtotal_cents:  0,
      total_cents:     0
    )
    order.add_product!(products(:shampoo_wella), 1)
    order
  end

  def billing_attrs
    {
      billing_first_name:      "María",
      billing_last_name:       "González",
      billing_document_type:   "rut",
      billing_document_number: "12.345.678-9",
      billing_email:           "maria@example.com",
      billing_phone:           "+56 9 1234 5678",
      shipping_type:           "pickup"
    }
  end

  def shipping_attrs
    {
      shipping_recipient_name: "María González",
      shipping_phone:          "+56 9 1234 5678",
      shipping_region:         "Metropolitana",
      shipping_comuna:         "Santiago",
      shipping_city:           "Santiago",
      shipping_street:         "Av. Providencia",
      shipping_street_number:  "1234"
    }
  end

  # ── Métodos helper ────────────────────────────────────────────────
  test "pickup? retorna true cuando shipping_type es pickup" do
    order = Order.new(shipping_type: "pickup")
    assert order.pickup?
    assert_not order.delivery?
  end

  test "delivery? retorna true cuando shipping_type es delivery" do
    order = Order.new(shipping_type: "delivery")
    assert order.delivery?
    assert_not order.pickup?
  end

  test "checkout? retorna true cuando status es checkout" do
    order = Order.new(status: "checkout")
    assert order.checkout?
  end

  # ── Validaciones de facturación (solo en checkout) ────────────────
  test "orden en cart es válida sin datos de facturación" do
    order = cart_with_product
    assert order.valid?
  end

  test "orden en checkout requiere todos los campos de facturación" do
    order = cart_with_product
    order.update_columns(status: "checkout", shipping_type: "pickup")

    assert_not order.valid?
    %i[billing_first_name billing_last_name billing_document_type
       billing_document_number billing_email billing_phone].each do |field|
      assert order.errors[field].any?, "Debería requerir #{field}"
    end
  end

  test "orden en checkout con todos los datos de facturación es válida (pickup)" do
    order = cart_with_product
    order.assign_attributes(billing_attrs)
    order.update_columns(status: "checkout")
    order.reload

    order.assign_attributes(billing_attrs)
    assert order.valid?, order.errors.full_messages.to_s
  end

  # ── Validaciones de envío (solo en checkout + delivery) ───────────
  test "checkout con pickup no requiere campos de dirección" do
    order = cart_with_product
    order.assign_attributes(billing_attrs.merge(shipping_type: "pickup"))
    order.update_columns(status: "checkout")
    order.reload
    order.assign_attributes(billing_attrs.merge(shipping_type: "pickup"))
    assert order.valid?, order.errors.full_messages.to_s
  end

  test "checkout con delivery requiere campos de dirección" do
    order = cart_with_product
    order.update_columns(status: "checkout")
    order.reload
    order.assign_attributes(billing_attrs.merge(shipping_type: "delivery"))

    assert_not order.valid?
    %i[shipping_region shipping_comuna shipping_city
       shipping_street shipping_street_number
       shipping_recipient_name shipping_phone].each do |field|
      assert order.errors[field].any?, "Debería requerir #{field}"
    end
  end

  test "checkout con delivery y datos completos es válido" do
    order = cart_with_product
    order.update_columns(status: "checkout")
    order.reload
    order.assign_attributes(
      billing_attrs.merge(shipping_type: "delivery").merge(shipping_attrs)
    )
    assert order.valid?, order.errors.full_messages.to_s
  end

  # ── Tipos de documento ────────────────────────────────────────────
  test "billing_document_type acepta rut, passport y dni" do
    %w[rut passport dni].each do |type|
      order = cart_with_product
      order.update_columns(status: "checkout")
      order.reload
      order.assign_attributes(billing_attrs.merge(billing_document_type: type))
      assert order.valid?, "Debería aceptar tipo '#{type}'"
    end
  end

  test "billing_document_type rechaza valores desconocidos" do
    order = cart_with_product
    order.update_columns(status: "checkout")
    order.reload
    order.assign_attributes(billing_attrs.merge(billing_document_type: "cedula"))
    assert_not order.valid?
    assert order.errors[:billing_document_type].any?
  end

  # ── Shipping type válido ──────────────────────────────────────────
  test "shipping_type acepta pickup y delivery" do
    %w[pickup delivery].each do |type|
      order = Order.new(shipping_type: type)
      order.valid?
      assert order.errors[:shipping_type].empty?, "Debería aceptar '#{type}'"
    end
  end

  test "shipping_type rechaza valores desconocidos" do
    order = Order.new(shipping_type: "drone")
    order.valid?
    assert order.errors[:shipping_type].any?
  end
end
