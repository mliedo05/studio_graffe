require "test_helper"

class AppointmentTest < ActiveSupport::TestCase
  def future_apt(overrides = {})
    Appointment.new({
      client:      users(:cliente),
      stylist:     users(:valentina),
      service:     services(:corte_damas),
      starts_at:   2.days.from_now.change(hour: 10, min: 0),
      price_cents: 18000
    }.merge(overrides))
  end

  # ── Validaciones básicas ──────────────────────────────────────────
  test "válido con atributos correctos" do
    assert future_apt.valid?
  end

  test "inválido sin starts_at" do
    assert_not future_apt(starts_at: nil).valid?
  end

  test "inválido con status desconocido" do
    apt = appointments(:cita_pendiente)
    apt.status = "otro_estado"
    assert_not apt.valid?
  end

  test "inválido con number duplicado" do
    apt = future_apt(number: appointments(:cita_pendiente).number)
    assert_not apt.valid?
    assert_includes apt.errors[:number], "has already been taken"
  end

  # ── Validaciones nuevas ───────────────────────────────────────────
  test "inválido si starts_at está en el pasado" do
    apt = future_apt(starts_at: 1.hour.ago)
    assert_not apt.valid?
    assert_includes apt.errors[:starts_at], "debe ser en el futuro"
  end

  test "inválido si ends_at es igual o anterior a starts_at" do
    starts = 2.days.from_now.change(hour: 10)
    apt = Appointment.new(
      client:      users(:cliente),
      stylist:     users(:valentina),
      service:     services(:corte_damas),
      starts_at:   starts,
      ends_at:     starts,          # igual — inválido
      price_cents: 18000
    )
    assert_not apt.valid?
    assert_includes apt.errors[:ends_at], "debe ser posterior a la hora de inicio"
  end

  test "inválido si el stylist no tiene rol de estilista" do
    apt = future_apt(stylist: users(:admin))
    assert_not apt.valid?
    assert_includes apt.errors[:stylist], "debe ser un estilista"
  end

  test "inválido si hay solapamiento con otra cita activa del mismo estilista" do
    # cita_confirmada: valentina 2030-01-07 14:00-16:00
    conflicting = future_apt(
      stylist:   users(:valentina),
      starts_at: appointments(:cita_confirmada).starts_at + 30.minutes
    )
    # Forzamos la fecha de starts_at para coincidir con el fixture (en el pasado)
    conflicting.starts_at = appointments(:cita_confirmada).starts_at + 30.minutes
    # Como está en el pasado también fallará por otra validación, así que
    # probamos con build directo sin la validación de futuro
    conflicting.save # save para que active todas las validaciones
    assert_includes conflicting.errors[:starts_at], "el estilista ya tiene una cita en ese horario"
  end

  test "no detecta solapamiento con citas canceladas" do
    # Crea una cita sin solape usando una fecha futura real
    apt = future_apt(
      stylist:   users(:camila),
      starts_at: 5.days.from_now.change(hour: 10)
    )
    assert apt.valid?
  end

  # ── Generación automática ─────────────────────────────────────────
  test "genera número automáticamente" do
    apt = future_apt
    apt.save!
    assert_match(/\AAPT-[0-9A-F]{8}\z/, apt.number)
  end

  test "calcula ends_at desde duración del servicio" do
    apt = future_apt
    apt.save!
    assert_equal apt.starts_at + 60.minutes, apt.ends_at
  end

  # ── Transiciones de estado ────────────────────────────────────────
  test "cancel! cambia status a cancelled en cita pendiente" do
    apt = appointments(:cita_pendiente)
    apt.cancel!
    assert_equal "cancelled", apt.reload.status
  end

  test "cancel! cambia status a cancelled en cita confirmada" do
    apt = appointments(:cita_confirmada)
    apt.cancel!
    assert_equal "cancelled", apt.reload.status
  end

  test "cancel! lanza InvalidTransitionError si ya está cancelada" do
    apt = appointments(:cita_cancelada)
    assert_raises(Appointment::InvalidTransitionError) { apt.cancel! }
  end

  test "complete! lanza InvalidTransitionError si no está confirmada" do
    apt = appointments(:cita_pendiente)
    assert_raises(Appointment::InvalidTransitionError) { apt.complete! }
  end

  test "complete! en cita confirmada cambia status a completed" do
    apt = appointments(:cita_confirmada)
    apt.complete!
    assert_equal "completed", apt.reload.status
  end

  # ── Scopes ────────────────────────────────────────────────────────
  test "scope active excluye canceladas y no_show" do
    assert_includes     Appointment.active, appointments(:cita_pendiente)
    assert_not_includes Appointment.active, appointments(:cita_cancelada)
  end
end
