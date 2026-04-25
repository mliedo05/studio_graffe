class Commission < ApplicationRecord
  monetize :amount_cents

  belongs_to :stylist, class_name: "User"
  belongs_to :appointment

  STATUSES = %w[pending paid cancelled].freeze

  validates :percentage,   numericality: { in: 0..100 }
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :paid,    -> { where(status: "paid") }

  def pay!
    update!(status: "paid", paid_at: Time.current)
  end
end
