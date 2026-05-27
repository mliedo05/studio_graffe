require "test_helper"

class AdminInventoryEntriesTest < ActionDispatch::IntegrationTest

  def setup
    sign_in_as users(:admin)
  end

  # ── GET /admin/inventory_entries ──────────────────────────────────

  test "GET /admin/inventory_entries devuelve 200" do
    get admin_inventory_entries_path
    assert_response :success
  end

  test "GET /admin/inventory_entries muestra los lotes existentes" do
    get admin_inventory_entries_path
    assert_select "td", text: /F-001-2026/
    assert_select "td", text: /Wella Chile/
  end

  # ── GET /admin/inventory_entries/new ─────────────────────────────

  test "GET /admin/inventory_entries/new devuelve 200" do
    get new_admin_inventory_entry_path
    assert_response :success
  end

  test "formulario tiene los campos requeridos" do
    get new_admin_inventory_entry_path
    assert_select "select[name='inventory_entry[product_id]']"
    assert_select "input[name='inventory_entry[invoice_number]']"
    assert_select "input[name='inventory_entry[supplier]']"
    assert_select "input[name='inventory_entry[quantity_received]']"
    assert_select "input[name='inventory_entry[unit_cost_cents]']"
  end

  # ── POST /admin/inventory_entries ────────────────────────────────

  test "POST válido crea la entrada y actualiza el stock del producto" do
    product    = products(:shampoo_wella)
    prev_stock = product.stock_quantity

    assert_difference "InventoryEntry.count", 1 do
      post admin_inventory_entries_path, params: {
        inventory_entry: {
          product_id:       product.id,
          quantity_received: 20,
          unit_cost_cents:   9500,
          supplier:          "Wella Chile",
          invoice_number:    "F-NUEVO-001",
          received_at:       Time.current.to_s
        }
      }
    end

    assert_redirected_to admin_inventory_entries_path
    assert_match "actualizado", flash[:notice]
    assert_equal prev_stock + 20, product.reload.stock_quantity
  end

  test "POST con quantity_received cero no crea la entrada" do
    assert_no_difference "InventoryEntry.count" do
      post admin_inventory_entries_path, params: {
        inventory_entry: {
          product_id:        products(:shampoo_wella).id,
          quantity_received:  0,
          unit_cost_cents:    9000,
          supplier:           "Test",
          invoice_number:     "F-BAD",
          received_at:        Time.current.to_s
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST con unit_cost_cents cero no crea la entrada" do
    assert_no_difference "InventoryEntry.count" do
      post admin_inventory_entries_path, params: {
        inventory_entry: {
          product_id:        products(:shampoo_wella).id,
          quantity_received:  10,
          unit_cost_cents:    0,
          supplier:           "Test",
          invoice_number:     "F-BAD",
          received_at:        Time.current.to_s
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST sin proveedor no crea la entrada" do
    assert_no_difference "InventoryEntry.count" do
      post admin_inventory_entries_path, params: {
        inventory_entry: {
          product_id:        products(:shampoo_wella).id,
          quantity_received:  10,
          unit_cost_cents:    9000,
          supplier:           "",
          invoice_number:     "F-BAD",
          received_at:        Time.current.to_s
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # ── GET /admin/inventory_entries/:id ─────────────────────────────

  test "GET show devuelve 200 con datos del lote" do
    get admin_inventory_entry_path(inventory_entries(:lote_wella_enero))
    assert_response :success
  end

  test "GET show muestra número de factura y proveedor" do
    entry = inventory_entries(:lote_wella_enero)
    get admin_inventory_entry_path(entry)
    assert_select "td", text: entry.invoice_number
    assert_select "td", text: entry.supplier
  end

  # ── Acceso sin autenticación ──────────────────────────────────────

  test "usuario no autenticado es redirigido al login" do
    delete destroy_user_session_path
    get admin_inventory_entries_path
    assert_response :redirect
  end
end
