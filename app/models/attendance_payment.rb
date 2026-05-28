class AttendancePayment < ApplicationRecord
  belongs_to :attendance

  monetize :amount_cents

  METHODS = %w[cash transfer card other pending].freeze
  METHOD_LABELS = {
    "cash"     => "Efectivo",
    "transfer" => "Transferencia",
    "card"     => "Tarjeta",
    "other"    => "Otro",
    "pending"  => "Pendiente de pago"
  }.freeze
  METHOD_COLORS = {
    "cash"     => "#16a34a",
    "transfer" => "#2563eb",
    "card"     => "#7c3aed",
    "other"    => "#6b7280",
    "pending"  => "#dc2626"
  }.freeze

  validates :payment_method, inclusion: { in: METHODS }
  validates :amount_cents, numericality: { greater_than: 0 }

  scope :real,    -> { where.not(payment_method: "pending") }
  scope :pending, -> { where(payment_method: "pending") }

  after_save    :recalculate_attendance
  after_destroy :recalculate_attendance

  def method_label
    METHOD_LABELS[payment_method] || payment_method
  end

  private

  def recalculate_attendance
    attendance.recalculate!
  end
end
