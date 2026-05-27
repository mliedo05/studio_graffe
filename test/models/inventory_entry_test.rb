require "test_helper"

class InventoryEntryTest < ActiveSupport::TestCase
  def valid_entry(product: products(:shampoo_wella), overrides: {})
    InventoryEntry.new({
      product:          product,
      quantity_received: 10,
      unit_cost_cents:   9000,
      supplier:          "Wella Chile",
      invoice_number:    "F-TEST-001",
      received_at:       Time.current
    }.merge(overrides))
  end

  # ── Validaciones ──────────────────────────────────────────────────

  test "es válido con todos los campos requeridos" do
    assert valid_entry.valid?
  end

  test "no es válido sin proveedor" do
    assert_not valid_entry(overrides: { supplier: nil }).valid?
  end

  test "no es válido sin número de factura" do
    assert_not valid_entry(overrides: { invoice_number: nil }).valid?
  end

  test "no es válido con cantidad cero" do
    assert_not valid_entry(overrides: { quantity_received: 0 }).valid?
  end

  test "no es válido con costo cero" do
    assert_not valid_entry(overrides: { unit_cost_cents: 0 }).valid?
  end

  test "quantity_remaining se inicializa igual a quantity_received" do
    entry = valid_entry
    entry.valid?
    assert_equal entry.quantity_received, entry.quantity_remaining
  end

  # ── fully_consumed? ───────────────────────────────────────────────

  test "fully_consumed? es false cuando quedan unidades" do
    assert_not inventory_entries(:lote_wella_enero).fully_consumed?
  end

  test "fully_consumed? es true cuando quantity_remaining es 0" do
    entry = inventory_entries(:lote_wella_enero)
    entry.quantity_remaining = 0
    assert entry.fully_consumed?
  end

  # ── scope available ───────────────────────────────────────────────

  test "scope available excluye lotes agotados" do
    entry = inventory_entries(:lote_wella_enero)
    entry.update!(quantity_remaining: 0)
    available = InventoryEntry.available.where(id: entry.id)
    assert_empty available
  end

  test "scope available ordena por received_at ascendente (FIFO)" do
    entries = products(:shampoo_wella).inventory_entries.available.to_a
    assert_equal entries, entries.sort_by(&:received_at)
  end

  # ── Product#receive_stock! ────────────────────────────────────────

  test "receive_stock! crea una entrada de inventario" do
    product = products(:shampoo_wella)
    assert_difference "InventoryEntry.count", 1 do
      product.receive_stock!(
        quantity:        5,
        unit_cost_cents: 9000,
        supplier:        "Proveedor Test",
        invoice_number:  "F-999"
      )
    end
  end

  test "receive_stock! incrementa el stock del producto" do
    product    = products(:shampoo_wella)
    stock_prev = product.stock_quantity
    product.receive_stock!(quantity: 5, unit_cost_cents: 9000,
                           supplier: "Test", invoice_number: "F-999")
    assert_equal stock_prev + 5, product.reload.stock_quantity
  end

  # ── Product#weighted_average_cost ────────────────────────────────

  test "weighted_average_cost retorna 0 sin entradas disponibles" do
    product = products(:olaplex)
    product.inventory_entries.update_all(quantity_remaining: 0)
    assert_equal 0, product.weighted_average_cost.fractional
  end

  test "weighted_average_cost calcula correctamente el promedio ponderado" do
    # lote_wella_enero: 15 uds a $9.000  → $135.000
    # lote_wella_marzo: 10 uds a $9.500  → $95.000
    # total: 25 uds, $230.000 → promedio $9.200
    product = products(:shampoo_wella)
    product.inventory_entries.update_all(quantity_remaining: 0) # limpiar otros
    product.inventory_entries.create!(quantity_received: 15, quantity_remaining: 15,
                                      unit_cost_cents: 9000, supplier: "Test",
                                      invoice_number: "A", received_at: 2.months.ago)
    product.inventory_entries.create!(quantity_received: 10, quantity_remaining: 10,
                                      unit_cost_cents: 9500, supplier: "Test",
                                      invoice_number: "B", received_at: 1.month.ago)
    assert_equal 9200, product.weighted_average_cost.fractional
  end

  # ── FIFO al vender ────────────────────────────────────────────────

  test "mark_paid! consume lotes en orden FIFO y graba costo en order_item" do
    user    = users(:cliente)
    product = products(:shampoo_wella)

    # Limpia entradas previas y crea dos lotes conocidos
    product.inventory_entries.destroy_all
    user.orders.where(status: "cart").destroy_all

    product.receive_stock!(quantity: 3, unit_cost_cents: 9000,
                           supplier: "Test", invoice_number: "L1",
                           received_at: 2.months.ago)
    product.receive_stock!(quantity: 10, unit_cost_cents: 9500,
                           supplier: "Test", invoice_number: "L2",
                           received_at: 1.month.ago)
    product.update!(stock_quantity: 13)

    cart = user.current_cart
    cart.add_product!(product, 5)  # consume 3 del lote L1 + 2 del lote L2

    billing = {
      billing_first_name: "Test", billing_last_name: "User",
      billing_document_type: "rut", billing_document_number: "12.345.678-9",
      billing_email: "test@example.com", billing_phone: "+56 9 0000 0000",
      shipping_type: "pickup"
    }
    cart.assign_attributes(billing)
    cart.checkout!
    cart.mark_paid!(transaction_id: "TXN-FIFO", payment_method: "efectivo")

    item = cart.order_items.find_by(product_id: product.id)

    # Costo FIFO: 3 uds × $9.000 + 2 uds × $9.500 = $27.000 + $19.000 = $46.000
    # unit_cost = $46.000 / 5 = $9.200
    assert_equal 9200,  item.reload.unit_cost_cents
    assert_equal 46000, item.reload.total_cost_cents

    # Lote L1 debe quedar agotado
    l1 = product.inventory_entries.order(:received_at).first
    assert_equal 0, l1.reload.quantity_remaining

    # Lote L2 debe quedar con 8 restantes
    l2 = product.inventory_entries.order(:received_at).last
    assert_equal 8, l2.reload.quantity_remaining
  end
end
