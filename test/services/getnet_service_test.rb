require "test_helper"
require "webmock/minitest"

class GetnetServiceTest < ActiveSupport::TestCase
  setup do
    @service  = GetnetService.new
    @base_url = GetnetService::SANDBOX_URL
  end

  # ── Instanciación ─────────────────────────────────────────────────

  test "se instancia correctamente en entorno de test" do
    assert_instance_of GetnetService, @service
  end

  test "usa el endpoint de sandbox fuera de producción" do
    assert_equal "https://checkout.test.getnet.cl", GetnetService::SANDBOX_URL
  end

  # ── Autenticación ─────────────────────────────────────────────────

  test "genera auth con los 4 campos requeridos" do
    auth = @service.send(:auth)
    assert auth[:login].present?,   "falta login"
    assert auth[:tranKey].present?, "falta tranKey"
    assert auth[:nonce].present?,   "falta nonce"
    assert auth[:seed].present?,    "falta seed"
  end

  test "auth seed es un timestamp ISO 8601" do
    auth = @service.send(:auth)
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, auth[:seed])
  end

  test "auth nonce es Base64 válido" do
    nonce = @service.send(:auth)[:nonce]
    assert_nothing_raised { Base64.strict_decode64(nonce) }
  end

  test "auth tranKey es Base64 válido" do
    tran_key = @service.send(:auth)[:tranKey]
    assert_nothing_raised { Base64.strict_decode64(tran_key) }
  end

  test "cada llamada a auth genera un nonce diferente" do
    nonce1 = @service.send(:auth)[:nonce]
    nonce2 = @service.send(:auth)[:nonce]
    assert_not_equal nonce1, nonce2
  end

  # ── create_transaction ────────────────────────────────────────────

  test "create_transaction retorna request_id y process_url cuando Getnet responde OK" do
    stub_request(:post, "#{@base_url}/api/session/")
      .to_return(
        status: 200,
        body: {
          status:     { status: "OK", message: "Procesado correctamente" },
          requestId:  "12345",
          processUrl: "#{@base_url}/spa/session/12345/abc123"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @service.create_transaction(
      orders(:orden_pagada),
      ip_address: "127.0.0.1",
      user_agent: "TestAgent",
      return_url: "http://localhost:3000/getnet/retorno",
      cancel_url: "http://localhost:3000/checkout"
    )

    assert_equal "12345",                       result[:request_id]
    assert_match "12345",                       result[:process_url]
  end

  test "create_transaction lanza GetnetError cuando Getnet responde con status FAILED" do
    stub_request(:post, "#{@base_url}/api/session/")
      .to_return(
        status: 200,
        body: { status: { status: "FAILED", message: "Autenticación fallida" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_raises GetnetService::GetnetError do
      @service.create_transaction(
        orders(:orden_pagada),
        ip_address: "127.0.0.1",
        user_agent: "TestAgent",
        return_url: "http://localhost:3000/getnet/retorno",
        cancel_url: "http://localhost:3000/checkout"
      )
    end
  end

  test "create_transaction lanza GetnetError si hay error de conexión" do
    stub_request(:post, "#{@base_url}/api/session/")
      .to_raise(Errno::ECONNREFUSED)

    assert_raises GetnetService::GetnetError do
      @service.create_transaction(
        orders(:orden_pagada),
        ip_address: "127.0.0.1",
        user_agent: "TestAgent",
        return_url: "http://localhost:3000/getnet/retorno",
        cancel_url: "http://localhost:3000/checkout"
      )
    end
  end

  # ── approved? ─────────────────────────────────────────────────────

  test "approved? retorna true cuando el status es APPROVED" do
    stub_request(:post, "#{@base_url}/api/session/12345")
      .to_return(
        status: 200,
        body:   { status: { status: "APPROVED" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    assert @service.approved?("12345")
  end

  test "approved? retorna false cuando el status es PENDING" do
    stub_request(:post, "#{@base_url}/api/session/12345")
      .to_return(
        status: 200,
        body:   { status: { status: "PENDING" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    assert_not @service.approved?("12345")
  end

  test "approved? retorna false cuando el status es REJECTED" do
    stub_request(:post, "#{@base_url}/api/session/12345")
      .to_return(
        status: 200,
        body:   { status: { status: "REJECTED" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    assert_not @service.approved?("12345")
  end
end
