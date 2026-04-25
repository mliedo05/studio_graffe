class Appointment < ApplicationRecord
  monetize :price_cents

  belongs_to :client,  class_name: "User"
  belongs_to :stylist, class_name: "User"
  belongs_to :service
  has_one :commission, dependent: :destroy

  STATUSES        = %w[pending confirmed completed cancelled no_show].freeze
  CANCELLABLE     = %w[pending confirmed].freeze
  CONFIRMABLE     = %w[pending].freeze

  validates :starts_at, :ends_at, :number, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :number, uniqueness: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }

  validate :starts_at_must_be_future,     on: :create
  validate :ends_at_must_be_after_starts_at
  validate :stylist_must_have_stylist_role
  validate :no_overlapping_appointments,  on: :create

  scope :upcoming, -> { where("starts_at > ?", Time.current).order(:starts_at) }
  scope :past,     -> { where("starts_at <= ?", Time.current).order(starts_at: :desc) }
  scope :active,   -> { where.not(status: %w[cancelled no_show]) }

  before_validation :set_number,   on: :create
  before_validation :set_ends_at,  on: :create

  def confirm!
    raise InvalidTransitionError, "Solo se pueden confirmar citas pendientes." unless CONFIRMABLE.include?(status)

    update!(status: "confirmed")
    Commission.create!(
      stylist:      stylist,
      appointment:  self,
      percentage:   stylist.stylist_profile&.commission_percentage || 35,
      amount_cents: (price_cents * (stylist.stylist_profile&.commission_percentage || 35) / 100.0).round
    )
  end

  def complete!
    raise InvalidTransitionError, "Solo se pueden completar citas confirmadas." unless status == "confirmed"
    update!(status: "completed")
  end

  def cancel!
    raise InvalidTransitionError, "Esta cita no se puede cancelar." unless CANCELLABLE.include?(status)
    update!(status: "cancelled")
    commission&.update!(status: "cancelled")
  end

  class InvalidTransitionError < StandardError; end

  private

  def set_number
    self.number ||= "APT-#{SecureRandom.hex(4).upcase}"
  end

  def set_ends_at
    self.ends_at ||= starts_at + service&.duration_minutes.to_i.minutes if starts_at && service
  end

  def starts_at_must_be_future
    return unless starts_at
    errors.add(:starts_at, "debe ser en el futuro") if starts_at <= Time.current
  end

  def ends_at_must_be_after_starts_at
    return unless starts_at && ends_at
    errors.add(:ends_at, "debe ser posterior a la hora de inicio") if ends_at <= starts_at
  end

  def stylist_must_have_stylist_role
    return unless stylist
    errors.add(:stylist, "debe ser un estilista") unless stylist.stylist?
  end

  def no_overlapping_appointments
    return unless stylist && starts_at && ends_at

    overlap = stylist.stylist_appointments
      .where.not(status: %w[cancelled no_show])
      .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
      .exists?

    errors.add(:starts_at, "el estilista ya tiene una cita en ese horario") if overlap
  end
end
