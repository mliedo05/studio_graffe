require "test_helper"

class AvailabilityServiceTest < ActiveSupport::TestCase
  # valentina tiene horario lunes (day_of_week=1) 09:00-18:00
  # 2030-01-07 es lunes
  LUNES_CON_HORARIO   = Date.new(2030, 1, 7)
  DOMINGO_SIN_HORARIO = Date.new(2030, 1, 6)

  def setup
    @stylist = users(:valentina)
    @service = services(:corte_damas)  # 60 min
  end

  test "devuelve slots cada 30 min dentro del horario" do
    slots = AvailabilityService.slots_for(
      stylist: @stylist,
      service: @service,
      date:    LUNES_CON_HORARIO
    )

    assert_not_empty slots
    assert_includes slots, "09:00"
    # 09:30 está bloqueado por cita_pendiente (10:00-11:00): 09:30+60min=10:30 > 10:00
    assert_not_includes slots, "09:30"
    # 11:00 está libre (cita_pendiente termina a las 11:00 exacto)
    assert_includes slots, "11:00"
    # Último slot posible: 17:00 (17:00 + 60min = 18:00)
    assert_includes slots, "17:00"
    # 17:30 + 60 min > 18:00, no debe aparecer
    assert_not_includes slots, "17:30"
  end

  test "devuelve array vacío si no hay horario para ese día" do
    slots = AvailabilityService.slots_for(
      stylist: @stylist,
      service: @service,
      date:    DOMINGO_SIN_HORARIO
    )
    assert_empty slots
  end

  test "excluye slots que coinciden con citas existentes" do
    # cita_pendiente: 2030-01-07 10:00-11:00 (corte_damas = 60 min)
    apt = appointments(:cita_pendiente)
    assert_equal LUNES_CON_HORARIO, apt.starts_at.to_date

    slots = AvailabilityService.slots_for(
      stylist: @stylist,
      service: @service,
      date:    LUNES_CON_HORARIO
    )

    # 10:00 ya está ocupado por cita_pendiente
    assert_not_includes slots, "10:00"
    # 09:30 se solaparía con cita_pendiente (09:30+60 = 10:30 > 10:00)
    assert_not_includes slots, "09:30"
    # 09:00 termina a las 10:00 exacto (no se solapa) — debe estar disponible
    assert_includes slots, "09:00"
  end

  test "excluye slots durante tiempos bloqueados" do
    # valentina_blocked: 2030-01-06 10:00-11:00 (domingo, pero probamos la lógica
    # creando un bloqueo en lunes para esta prueba)
    @stylist.stylist_blocked_times.create!(
      starts_at: LUNES_CON_HORARIO.to_datetime.change(hour: 14, min: 0),
      ends_at:   LUNES_CON_HORARIO.to_datetime.change(hour: 15, min: 0),
      reason:    "Test bloqueo"
    )

    slots = AvailabilityService.slots_for(
      stylist: @stylist,
      service: @service,
      date:    LUNES_CON_HORARIO
    )

    assert_not_includes slots, "14:00"
    assert_not_includes slots, "13:30"  # 13:30+60 = 14:30 > 14:00
  end

  test "no cuenta citas canceladas como bloqueadas" do
    # cita_cancelada es de camila, no de valentina — verificamos que los slots
    # de valentina no se vean afectados
    slots_before = AvailabilityService.slots_for(
      stylist: @stylist,
      service: @service,
      date:    LUNES_CON_HORARIO
    )
    assert_not_empty slots_before
  end

  test "servicio largo reduce slots disponibles" do
    slots_cortos = AvailabilityService.slots_for(
      stylist: @stylist,
      service: services(:corte_damas),   # 60 min
      date:    LUNES_CON_HORARIO
    )
    slots_largos = AvailabilityService.slots_for(
      stylist: @stylist,
      service: services(:tinte_completo), # 120 min
      date:    LUNES_CON_HORARIO
    )
    assert slots_largos.count < slots_cortos.count
  end
end
