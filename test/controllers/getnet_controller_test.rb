require "test_helper"
require "webmock/minitest"

class GetnetControllerTest < ActionDispatch::IntegrationTest
  GETNET_BASE = GetnetService::SANDBOX_URL

  # ── Helpers ───────────────────────────────────────────────────────

  def checkout_order
    order = orders(:orden_pagada)
    order.update_columns(status: "checkout", payment_token: "REQ-123")
    order
  end

  def stub_getnet_approved
    stub_request(:post, "#{GETNET_BASE}/api/session/REQ-123")
      .to_return(
        status: 200,
        body:   { status: { status: "APPROVED" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_getnet_rejected
    stub_request(:post, "#{GETNET_BASE}/api/session/REQ-123")
      .to_return(
        status: 200,
        body:   { status: { status: "REJECTED" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  # ── GET /getnet/retorno — pago aprobado ───────────────────────────

  test "retorno aprobado redirige a tienda con notice" do
    stub_getnet_approved
    order = checkout_order
    get getnet_return_path(order: order.number)
    assert_redirected_to shop_path
    assert_match "confirmado", flash[:notice]
  end

  test "retorno aprobado marca la orden como paid" do
    stub_getnet_approved
    order = checkout_order
    get getnet_return_path(order: order.number)
    assert_equal "paid", order.reload.status
  end

  test "retorno aprobado guarda payment_method getnet" do
    stub_getnet_approved
    order = checkout_order
    get getnet_return_path(order: order.number)
    assert_equal "getnet", order.reload.payment_method
  end

  test "retorno aprobado encola email de confirmación" do
    stub_getnet_approved
    order = checkout_order
    assert_enqueued_emails 1 do
      get getnet_return_path(order: order.number)
    end
  end

  # ── GET /getnet/retorno — pago rechazado ──────────────────────────

  test "retorno rechazado redirige al checkout con alerta" do
    stub_getnet_rejected
    order = checkout_order
    get getnet_return_path(order: order.number)
    assert_redirected_to checkout_path
    assert flash[:alert].present?
  end

  test "retorno rechazado restaura la orden a status cart" do
    stub_getnet_rejected
    order = checkout_order
    get getnet_return_path(order: order.number)
    assert_equal "cart", order.reload.status
  end

  # ── GET /getnet/retorno — orden ya pagada ─────────────────────────

  test "retorno con orden ya pagada redirige a tienda directamente" do
    order = orders(:orden_pagada) # status ya es paid
    get getnet_return_path(order: order.number)
    assert_redirected_to shop_path
  end

  # ── GET /getnet/retorno — orden no encontrada ─────────────────────

  test "retorno con order inexistente redirige a tienda con alerta" do
    get getnet_return_path(order: "ORD-INEXISTENTE")
    assert_redirected_to shop_path
    assert flash[:alert].present?
  end

  # ── POST /getnet/notificacion — webhook ───────────────────────────

  test "notificación APPROVED confirma la orden" do
    order = checkout_order
    post getnet_notification_path,
         params:  { requestId: "REQ-123", status: { status: "APPROVED" } }.to_json,
         headers: { "Content-Type" => "application/json" }
    assert_response :ok
    assert_equal "paid", order.reload.status
  end

  test "notificación REJECTED no cambia la orden" do
    order = checkout_order
    post getnet_notification_path,
         params:  { requestId: "REQ-123", status: { status: "REJECTED" } }.to_json,
         headers: { "Content-Type" => "application/json" }
    assert_response :ok
    assert_equal "checkout", order.reload.status
  end

  test "notificación con requestId desconocido responde 200 sin error" do
    post getnet_notification_path,
         params:  { requestId: "INEXISTENTE", status: { status: "APPROVED" } }.to_json,
         headers: { "Content-Type" => "application/json" }
    assert_response :ok
  end

  test "notificación no procesa orden ya pagada dos veces" do
    order = orders(:orden_pagada)
    order.update_columns(payment_token: "REQ-PAID")
    assert_no_difference "Order.where(status: 'paid').count" do
      post getnet_notification_path,
           params:  { requestId: "REQ-PAID", status: { status: "APPROVED" } }.to_json,
           headers: { "Content-Type" => "application/json" }
    end
  end
end
