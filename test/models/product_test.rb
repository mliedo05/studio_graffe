require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "válido con atributos correctos" do
    product = Product.new(
      name: "Nuevo Shampoo",
      brand: "TestBrand",
      price_cents: 10000,
      stock_quantity: 5,
      product_category: product_categories(:shampoo)
    )
    assert product.valid?
  end

  test "inválido sin name" do
    products(:shampoo_wella).tap { |p| p.name = nil; assert_not p.valid? }
  end

  test "inválido sin brand" do
    products(:shampoo_wella).tap { |p| p.brand = nil; assert_not p.valid? }
  end

  test "inválido con price_cents negativo" do
    products(:shampoo_wella).tap { |p| p.price_cents = -100; assert_not p.valid? }
  end

  test "inválido con stock_quantity negativo" do
    products(:shampoo_wella).tap { |p| p.stock_quantity = -1; assert_not p.valid? }
  end

  test "inválido con nombre duplicado en la misma marca" do
    dup = Product.new(
      name:             products(:shampoo_wella).name,
      brand:            products(:shampoo_wella).brand,
      price_cents:      5000,
      stock_quantity:   1,
      product_category: product_categories(:shampoo)
    )
    assert_not dup.valid?
    assert dup.errors[:name].any?
  end

  test "permite el mismo nombre en distinta marca" do
    dup = Product.new(
      name:             products(:shampoo_wella).name,
      brand:            "OtraMarca",
      price_cents:      5000,
      stock_quantity:   1,
      product_category: product_categories(:shampoo)
    )
    assert dup.valid?
  end

  test "genera slug automáticamente" do
    product = Product.create!(
      name: "Mi Shampoo Especial", brand: "BrandTest",
      price_cents: 5000, stock_quantity: 1,
      product_category: product_categories(:shampoo)
    )
    assert_equal "brandtest-mi-shampoo-especial", product.slug
  end

  test "in_stock? devuelve true cuando hay stock" do
    assert products(:shampoo_wella).in_stock?
  end

  test "in_stock? devuelve false cuando no hay stock" do
    assert_not products(:olaplex).in_stock?
  end

  test "scope active excluye inactivos" do
    assert_includes     Product.active, products(:shampoo_wella)
    assert_not_includes Product.active, products(:producto_inactivo)
  end

  test "scope featured filtra destacados" do
    assert_includes     Product.featured, products(:shampoo_wella)
    assert_not_includes Product.featured, products(:acondicionador_wella)
  end

  test "scope in_stock filtra con stock > 0" do
    assert_includes     Product.in_stock, products(:shampoo_wella)
    assert_not_includes Product.in_stock, products(:olaplex)
  end

  # ── receive_stock! ────────────────────────────────────────────────

  test "receive_stock! crea un lote con los datos correctos" do
    product = products(:shampoo_wella)
    entry = product.receive_stock!(
      quantity:        10,
      unit_cost_cents: 8500,
      supplier:        "Distribuidora Test",
      invoice_number:  "F-100",
      received_at:     Time.current,
      notes:           "Lote de prueba"
    )
    assert_equal 10,    entry.quantity_received
    assert_equal 10,    entry.quantity_remaining
    assert_equal 8500,  entry.unit_cost_cents
    assert_equal "Distribuidora Test", entry.supplier
    assert_equal "F-100",             entry.invoice_number
    assert_equal "Lote de prueba",    entry.notes
  end

  test "receive_stock! incrementa stock_quantity del producto" do
    product    = products(:shampoo_wella)
    prev_stock = product.stock_quantity
    product.receive_stock!(quantity: 7, unit_cost_cents: 9000,
                           supplier: "S", invoice_number: "F-X")
    assert_equal prev_stock + 7, product.reload.stock_quantity
  end

  test "receive_stock! es atómico: revierte si falla" do
    product = products(:shampoo_wella)
    prev_stock = product.stock_quantity
    assert_raises(ActiveRecord::RecordInvalid) do
      product.receive_stock!(quantity: 5, unit_cost_cents: 0,  # costo 0 falla validación
                             supplier: "S", invoice_number: "F-X")
    end
    assert_equal prev_stock, product.reload.stock_quantity
  end

  # ── weighted_average_cost ─────────────────────────────────────────

  test "weighted_average_cost es 0 cuando no hay lotes disponibles" do
    product = products(:shampoo_wella)
    product.inventory_entries.destroy_all
    assert_equal 0, product.weighted_average_cost.fractional
  end

  test "weighted_average_cost pondera correctamente dos lotes" do
    product = products(:shampoo_wella)
    product.inventory_entries.destroy_all
    # Lote A: 4 uds × $10.000 = $40.000
    # Lote B: 6 uds × $12.000 = $72.000
    # Promedio ponderado: $112.000 / 10 = $11.200
    product.inventory_entries.create!(quantity_received: 4, quantity_remaining: 4,
                                      unit_cost_cents: 10000, supplier: "S",
                                      invoice_number: "A", received_at: 2.days.ago)
    product.inventory_entries.create!(quantity_received: 6, quantity_remaining: 6,
                                      unit_cost_cents: 12000, supplier: "S",
                                      invoice_number: "B", received_at: 1.day.ago)
    assert_equal 11200, product.weighted_average_cost.fractional
  end

  # ── Insumo de salón ───────────────────────────────────────────────

  test "scope insumos incluye solo productos con track_in_grams = true" do
    assert_includes     Product.insumos, products(:tinte_insumo)
    assert_not_includes Product.insumos, products(:shampoo_wella)
  end

  test "scope for_sale excluye productos insumo" do
    assert_includes     Product.for_sale, products(:shampoo_wella)
    assert_not_includes Product.for_sale, products(:tinte_insumo)
  end

  test "default_commission_percent por defecto es 10" do
    product = Product.new(name: "X", brand: "Y", price_cents: 0,
                          stock_quantity: 1, product_category: product_categories(:shampoo))
    assert_equal 10, product.default_commission_percent
  end

  test "default_commission_percent acepta 0" do
    product = products(:shampoo_wella)
    product.default_commission_percent = 0
    assert product.valid?
  end

  test "default_commission_percent rechaza valores fuera de 0..100" do
    product = products(:shampoo_wella)
    product.default_commission_percent = 110
    assert_not product.valid?
    assert product.errors[:default_commission_percent].any?
  end

  test "válido con track_in_grams y cost_per_gram_cents" do
    product = Product.new(
      name:               "Tinte Castaño Medio",
      brand:              "Koleston",
      price_cents:        0,
      stock_quantity:     200,
      track_in_grams:     true,
      cost_per_gram_cents: 500,
      product_category:   product_categories(:tratamientos)
    )
    assert product.valid?, product.errors.full_messages.inspect
  end

  test "cost_per_gram_cents por defecto es 0" do
    product = Product.new(name: "X", brand: "Y", price_cents: 0,
                          stock_quantity: 1, product_category: product_categories(:shampoo))
    assert_equal 0, product.cost_per_gram_cents
  end

  test "track_in_grams por defecto es false" do
    product = Product.new(name: "X", brand: "Y", price_cents: 0,
                          stock_quantity: 1, product_category: product_categories(:shampoo))
    assert_not product.track_in_grams
  end

  test "weighted_average_cost ignora lotes agotados" do
    product = products(:shampoo_wella)
    product.inventory_entries.destroy_all
    # Lote agotado a $5.000 no debe influir
    product.inventory_entries.create!(quantity_received: 10, quantity_remaining: 0,
                                      unit_cost_cents: 5000, supplier: "S",
                                      invoice_number: "OLD", received_at: 1.month.ago)
    product.inventory_entries.create!(quantity_received: 5, quantity_remaining: 5,
                                      unit_cost_cents: 9000, supplier: "S",
                                      invoice_number: "NEW", received_at: 1.day.ago)
    assert_equal 9000, product.weighted_average_cost.fractional
  end
end
