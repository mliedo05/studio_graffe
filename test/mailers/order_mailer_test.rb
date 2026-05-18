require "test_helper"

class OrderMailerTest < ActionMailer::TestCase
  setup do
    @user  = users(:cliente)
    @order = orders(:orden_pagada)
  end

  # ── confirmation ─────────────────────────────────────────────────

  test "confirmation: se envía al email del usuario" do
    mail = OrderMailer.confirmation(@order)
    assert_equal [@user.email], mail.to
  end

  test "confirmation: from es Studio Graffé" do
    mail = OrderMailer.confirmation(@order)
    assert_match "studiograffe.cl", mail.from.first
  end

  test "confirmation: subject incluye el número de orden" do
    mail = OrderMailer.confirmation(@order)
    assert_match @order.number, mail.subject
  end

  test "confirmation: subject indica que el pedido fue confirmado" do
    mail = OrderMailer.confirmation(@order)
    assert_match "confirmado", mail.subject.downcase
  end

  test "confirmation HTML: incluye el nombre del usuario" do
    mail = OrderMailer.confirmation(@order)
    assert_match @user.first_name, mail.html_part.body.to_s
  end

  test "confirmation HTML: incluye el número de orden" do
    mail = OrderMailer.confirmation(@order)
    assert_match @order.number, mail.html_part.body.to_s
  end

  test "confirmation HTML: incluye el total de la orden" do
    mail = OrderMailer.confirmation(@order)
    assert_match @order.number, mail.html_part.body.to_s
  end

  test "confirmation HTML: incluye el email del usuario en el footer" do
    mail = OrderMailer.confirmation(@order)
    assert_match @user.email, mail.html_part.body.to_s
  end

  test "confirmation HTML: muestra los productos del pedido" do
    mail  = OrderMailer.confirmation(@order)
    body  = mail.html_part.body.to_s
    @order.order_items.includes(:product).each do |item|
      assert_match item.product.name, body
    end
  end

  test "confirmation texto: incluye el número de orden" do
    mail = OrderMailer.confirmation(@order)
    assert_match @order.number, mail.text_part.body.to_s
  end

  test "confirmation texto: incluye el nombre del usuario" do
    mail = OrderMailer.confirmation(@order)
    assert_match @user.first_name, mail.text_part.body.to_s
  end

  test "confirmation texto: incluye los productos" do
    mail = OrderMailer.confirmation(@order)
    body = mail.text_part.body.to_s
    @order.order_items.includes(:product).each do |item|
      assert_match item.product.name, body
    end
  end

  # ── Envío diferido ────────────────────────────────────────────────

  test "confirmation se puede encolar con deliver_later" do
    assert_enqueued_emails 1 do
      OrderMailer.confirmation(@order).deliver_later
    end
  end

end
