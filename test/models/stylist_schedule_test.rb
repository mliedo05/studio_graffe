require "test_helper"

class StylistScheduleTest < ActiveSupport::TestCase
  test "válido con atributos correctos" do
    schedule = StylistSchedule.new(
      stylist:     users(:valentina),
      day_of_week: 3,
      start_time:  "09:00",
      end_time:    "18:00"
    )
    assert schedule.valid?
  end

  test "inválido con day_of_week fuera de rango" do
    schedule = stylist_schedules(:valentina_lunes)
    schedule.day_of_week = 7
    assert_not schedule.valid?
  end

  test "inválido sin start_time" do
    schedule = stylist_schedules(:valentina_lunes)
    schedule.start_time = nil
    assert_not schedule.valid?
  end

  test "inválido sin end_time" do
    schedule = stylist_schedules(:valentina_lunes)
    schedule.end_time = nil
    assert_not schedule.valid?
  end

  test "inválido con combinación stylist+day_of_week duplicada" do
    schedule = StylistSchedule.new(
      stylist:     users(:valentina),
      day_of_week: 1,
      start_time:  "10:00",
      end_time:    "17:00"
    )
    assert_not schedule.valid?
  end

  test "inválido si end_time es igual a start_time" do
    schedule = StylistSchedule.new(
      stylist:     users(:valentina),
      day_of_week: 4,
      start_time:  "10:00",
      end_time:    "10:00"
    )
    assert_not schedule.valid?
    assert_includes schedule.errors[:end_time], "debe ser posterior a la hora de inicio"
  end

  test "inválido si end_time es anterior a start_time" do
    schedule = StylistSchedule.new(
      stylist:     users(:valentina),
      day_of_week: 5,
      start_time:  "18:00",
      end_time:    "09:00"
    )
    assert_not schedule.valid?
    assert_includes schedule.errors[:end_time], "debe ser posterior a la hora de inicio"
  end
end
