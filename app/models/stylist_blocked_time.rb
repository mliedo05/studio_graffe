class StylistBlockedTime < ApplicationRecord
  belongs_to :stylist, class_name: "User"

  validates :starts_at, :ends_at, presence: true
  validate  :ends_at_must_be_after_starts_at

  private

  def ends_at_must_be_after_starts_at
    return unless starts_at && ends_at
    errors.add(:ends_at, "debe ser posterior a la hora de inicio") if ends_at <= starts_at
  end
end
