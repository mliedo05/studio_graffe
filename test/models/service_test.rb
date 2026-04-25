require "test_helper"

class ServiceTest < ActiveSupport::TestCase
  test "válido con atributos correctos" do
    service = Service.new(
      name: "Nuevo servicio",
      category: "Cortes",
      price_cents: 15000,
      duration_minutes: 45
    )
    assert service.valid?
  end

  test "inválido sin name" do
    service = services(:corte_damas)
    service.name = nil
    assert_not service.valid?
  end

  test "inválido sin category" do
    service = services(:corte_damas)
    service.category = nil
    assert_not service.valid?
  end

  test "inválido con duration_minutes cero" do
    service = services(:corte_damas)
    service.duration_minutes = 0
    assert_not service.valid?
  end

  test "inválido con price_cents negativo" do
    service = services(:corte_damas)
    service.price_cents = -1
    assert_not service.valid?
  end

  test "scope active excluye servicios inactivos" do
    activos = Service.active
    assert_includes activos, services(:corte_damas)
    assert_not_includes activos, services(:servicio_inactivo)
  end

  test "scope ordered ordena por position" do
    ordered = Service.active.ordered.to_a
    assert ordered.first.position <= ordered.last.position
  end
end
