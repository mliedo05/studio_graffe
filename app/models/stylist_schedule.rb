class StylistSchedule < ApplicationRecord
  belongs_to :stylist, class_name: "User"

  validates :day_of_week, inclusion: { in: 0..6 }
  validates :day_of_week, uniqueness: { scope: :stylist_id }
  validates :start_time, :end_time, presence: true
  validate  :end_time_must_be_after_start_time

  private

  def end_time_must_be_after_start_time
    return unless start_time && end_time
    errors.add(:end_time, "debe ser posterior a la hora de inicio") if end_time <= start_time
  end
end
