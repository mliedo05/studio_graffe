require "test_helper"

class AttendanceItemTest < ActiveSupport::TestCase
  # ── Validaciones ──────────────────────────────────────────────────

  test "válido con atributos correctos (servicio)" do
    item = AttendanceItem.new(
      attendance:         attendances(:atencion_cerrada),
      stylist:            users(:valentina),
      service:            services(:corte_damas),
      item_type:          "service",
      price_cents:        119000,
      commission_percent: 40
    )
    assert item.valid?, item.errors.full_messages.inspect
  end

  test "válido con atributos correctos (producto)" do
    item = AttendanceItem.new(
      attendance:         attendances(:atencion_cerrada),
      stylist:            users(:valentina),
      product:            products(:shampoo_wella),
      item_type:          "product",
      price_cents:        18990,
      commission_percent: 10
    )
    assert item.valid?, item.errors.full_messages.inspect
  end

  test "inválido con item_type desconocido" do
    item = AttendanceItem.new(
      attendance:         attendances(:atencion_cerrada),
      stylist:            users(:valentina),
      item_type:          "gift",
      price_cents:        10000,
      commission_percent: 0
    )
    assert_not item.valid?
    assert item.errors[:item_type].any?
  end

  test "inválido con commission_percent fuera de rango" do
    item = attendance_items(:item_servicio)
    item.commission_percent = 110
    assert_not item.valid?
  end

  test "inválido con price_cents negativo" do
    item = attendance_items(:item_servicio)
    item.price_cents = -1
    assert_not item.valid?
  end

  test "servicio requiere association service presente" do
    item = AttendanceItem.new(
      attendance:         attendances(:atencion_cerrada),
      stylist:            users(:valentina),
      item_type:          "service",
      price_cents:        10000,
      commission_percent: 0
    )
    assert_not item.valid?
    assert item.errors[:service].any?
  end

  # ── IVA_FACTOR y cálculo de neto ─────────────────────────────────

  test "IVA_FACTOR es 1.19" do
    assert_equal 1.19, AttendanceItem::IVA_FACTOR
  end

  test "net_price_cents calcula precio sin IVA 19%" do
    item = attendance_items(:item_servicio)
    # $119.000 / 1.19 = $100.000
    assert_equal 100000, item.net_price_cents
  end

  test "iva_cents devuelve el IVA incluido en el precio" do
    item = attendance_items(:item_servicio)
    # $119.000 - $100.000 = $19.000
    assert_equal 19000, item.iva_cents
  end

  test "studio_cents devuelve neto menos comisión" do
    item = attendance_items(:item_servicio)
    # neto $100.000 - comisión $40.000 = $60.000
    assert_equal 60000, item.studio_cents
  end

  # ── Cálculo de comisión sobre neto ───────────────────────────────

  test "calculate_commission usa el precio NETO (sin IVA)" do
    item = AttendanceItem.new(
      attendance:         attendances(:atencion_cerrada),
      stylist:            users(:valentina),
      service:            services(:corte_damas),
      item_type:          "service",
      price_cents:        119000,
      commission_percent: 40
    )
    item.valid?   # dispara before_validation
    # neto = 100.000 · 40% = 40.000
    assert_equal 40000, item.commission_cents
  end

  test "comisión 0% resulta en commission_cents 0" do
    item = AttendanceItem.new(
      attendance:         attendances(:atencion_cerrada),
      stylist:            users(:valentina),
      service:            services(:corte_damas),
      item_type:          "service",
      price_cents:        119000,
      commission_percent: 0
    )
    item.valid?
    assert_equal 0, item.commission_cents
  end

  test "comisión NO se calcula sobre precio bruto (con IVA)" do
    item = AttendanceItem.new(
      attendance:         attendances(:atencion_cerrada),
      stylist:            users(:valentina),
      service:            services(:corte_damas),
      item_type:          "service",
      price_cents:        119000,
      commission_percent: 40
    )
    item.valid?
    # Si fuera sobre bruto: 119.000 * 40% = 47.600. Debe ser 40.000.
    assert_not_equal 47600, item.commission_cents
    assert_equal     40000, item.commission_cents
  end

  # ── set_description ───────────────────────────────────────────────

  test "set_description auto-llena desde el nombre del servicio" do
    item = AttendanceItem.new(
      attendance:         attendances(:atencion_cerrada),
      stylist:            users(:valentina),
      service:            services(:corte_damas),
      item_type:          "service",
      price_cents:        10000,
      commission_percent: 0
    )
    item.valid?
    assert_equal "Corte Damas", item.description
  end

  test "set_description no sobreescribe si ya tiene valor" do
    item = AttendanceItem.new(
      attendance:         attendances(:atencion_cerrada),
      stylist:            users(:valentina),
      service:            services(:corte_damas),
      item_type:          "service",
      description:        "Descripción personalizada",
      price_cents:        10000,
      commission_percent: 0
    )
    item.valid?
    assert_equal "Descripción personalizada", item.description
  end

  # ── Helpers item_type ─────────────────────────────────────────────

  test "service? devuelve true para item de tipo service" do
    assert attendance_items(:item_servicio).service?
    assert_not attendance_items(:item_servicio).product?
  end

  test "product? devuelve true para item de tipo product" do
    assert attendance_items(:item_producto).product?
    assert_not attendance_items(:item_producto).service?
  end
end
