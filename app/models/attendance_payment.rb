class AttendancePayment < ApplicationRecord
  belongs_to :attendance

  monetize :amount_cents

  METHODS = %w[cash transfer card other].freeze
  METHOD_LABELS = {
    "cash"     => "Efectivo",
    "transfer" => "Transferencia",
    "card"     => "Tarjeta",
    "other"    => "Otro"
  }.freeze

  validates :payment_method, inclusion: { in: METHODS }
  validates :amount_cents, numericality: { greater_than: 0 }

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
