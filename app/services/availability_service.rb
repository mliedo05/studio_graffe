class AvailabilityService
  SLOT_DURATION = 30.minutes

  def self.slots_for(stylist:, service:, date:)
    schedule = stylist.stylist_schedules.find_by(day_of_week: date.wday, active: true)
    return [] unless schedule

    existing = stylist.stylist_appointments
      .where(starts_at: date.beginning_of_day..date.end_of_day)
      .where.not(status: %w[cancelled no_show])

    blocked = stylist.stylist_blocked_times
      .where("starts_at <= ? AND ends_at >= ?", date.end_of_day, date.beginning_of_day)

    slots   = []
    current = DateTime.new(date.year, date.month, date.day, schedule.start_time.hour, schedule.start_time.min)
    finish  = DateTime.new(date.year, date.month, date.day, schedule.end_time.hour, schedule.end_time.min)

    while current + service.duration_minutes.minutes <= finish
      slot_end   = current + service.duration_minutes.minutes
      overlaps   = existing.any? { |a| a.starts_at < slot_end && a.ends_at > current }
      is_blocked = blocked.any? { |b| b.starts_at < slot_end && b.ends_at > current }

      slots << current.strftime("%H:%M") unless overlaps || is_blocked
      current += SLOT_DURATION
    end

    slots
  end
end
