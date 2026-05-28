require "test_helper"

class AddressTest < ActiveSupport::TestCase
  def valid_attrs(overrides = {})
    {
      user:           users(:cliente),
      label:          "Casa",
      recipient_name: "María González",
      phone:          "+56 9 1234 5678",
      region:         "Metropolitana",
      comuna:         "Santiago",
      city:           "Santiago",
      street:         "Av. Providencia",
      street_number:  "1234"
    }.merge(overrides)
  end

  # ── Validaciones de presencia ─────────────────────────────────────
  test "válida con todos los atributos correctos" do
    assert Address.new(valid_attrs).valid?
  end

  %i[recipient_name phone region comuna city street street_number label].each do |field|
    test "inválida sin #{field}" do
      addr = Address.new(valid_attrs(field => nil))
      assert_not addr.valid?
      assert addr.errors[field].any?
    end
  end

  # ── Validación de región ──────────────────────────────────────────
  test "inválida con región desconocida" do
    addr = Address.new(valid_attrs(region: "Región Fantasma"))
    assert_not addr.valid?
    assert addr.errors[:region].any?
  end

  test "válida con cada región de Chile" do
    Address::REGIONS.keys.each do |region|
      primera_comuna = Address::REGIONS[region].first
      addr = Address.new(valid_attrs(region: region, comuna: primera_comuna))
      assert addr.valid?, "Debería ser válida con región '#{region}'"
    end
  end

  # ── Validación comuna pertenece a región ─────────────────────────
  test "inválida si comuna no pertenece a la región" do
    addr = Address.new(valid_attrs(region: "Metropolitana", comuna: "Iquique"))
    assert_not addr.valid?
    assert addr.errors[:comuna].any?
  end

  test "válida si comuna pertenece a la región" do
    addr = Address.new(valid_attrs(region: "Tarapacá", comuna: "Iquique"))
    assert addr.valid?
  end

  # ── comunas_for ───────────────────────────────────────────────────
  test "comunas_for devuelve array de comunas para una región válida" do
    comunas = Address.comunas_for("Metropolitana")
    assert_includes comunas, "Santiago"
    assert_includes comunas, "Providencia"
  end

  test "comunas_for devuelve array vacío para región desconocida" do
    assert_equal [], Address.comunas_for("Inexistente")
  end

  # ── Apartment opcional ────────────────────────────────────────────
  test "válida sin apartment" do
    assert Address.new(valid_attrs(apartment: nil)).valid?
  end

  test "válida con apartment" do
    assert Address.new(valid_attrs(apartment: "Depto 4B")).valid?
  end

  # ── Default único ─────────────────────────────────────────────────
  test "al marcar una dirección como default, las otras del mismo usuario pierden el default" do
    user  = users(:cliente)
    addr1 = Address.create!(valid_attrs(user: user, label: "Casa", default: true))
    addr2 = Address.create!(valid_attrs(user: user, label: "Trabajo", default: true))

    assert_not addr1.reload.default?, "addr1 debería dejar de ser default"
    assert     addr2.reload.default?, "addr2 debería ser default"
  end

  test "marcar default no afecta las direcciones de otro usuario" do
    user1 = users(:cliente)
    user2 = users(:admin)

    addr1 = Address.create!(valid_attrs(user: user1, label: "Casa", default: true))
    addr2 = Address.create!(valid_attrs(user: user2, label: "Casa", default: true))

    assert addr1.reload.default?
    assert addr2.reload.default?
  end
end
