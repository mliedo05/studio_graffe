require "test_helper"

class StylistBlockedTimeTest < ActiveSupport::TestCase
  test "válido con atributos correctos" do
    blocked = StylistBlockedTime.new(
      stylist:   users(:valentina),
      starts_at: 1.day.from_now,
      ends_at:   1.day.from_now + 2.hours
    )
    assert blocked.valid?
  end

  test "inválido sin starts_at" do
    blocked = stylist_blocked_times(:valentina_blocked)
    blocked.starts_at = nil
    assert_not blocked.valid?
  end

  test "inválido sin ends_at" do
    blocked = stylist_blocked_times(:valentina_blocked)
    blocked.ends_at = nil
    assert_not blocked.valid?
  end

  test "inválido si ends_at es igual a starts_at" do
    time = 1.day.from_now
    blocked = StylistBlockedTime.new(
      stylist:   users(:valentina),
      starts_at: time,
      ends_at:   time
    )
    assert_not blocked.valid?
    assert_includes blocked.errors[:ends_at], "debe ser posterior a la hora de inicio"
  end

  test "inválido si ends_at es anterior a starts_at" do
    blocked = StylistBlockedTime.new(
      stylist:   users(:valentina),
      starts_at: 2.days.from_now,
      ends_at:   1.day.from_now
    )
    assert_not blocked.valid?
    assert_includes blocked.errors[:ends_at], "debe ser posterior a la hora de inicio"
  end
end
