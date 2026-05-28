class AttendanceItem < ApplicationRecord
  belongs_to :attendance
  belongs_to :stylist,  class_name: "User"
  belongs_to :service,  optional: true
  belongs_to :product,  optional: true

  monetize :price_cents
  monetize :commission_cents

  ITEM_TYPES = %w[service product].freeze

  validates :item_type,          inclusion: { in: ITEM_TYPES }
  validates :description, presence: true
  validates :price_cents,        numericality: { greater_than_or_equal_to: 0 }
  validates :commission_percent, numericality: { in: 0..100 }
  validates :commission_cents,   numericality: { greater_than_or_equal_to: 0 }
  validates :service, presence: true, if: -> { item_type == "service" }
  validates :product, presence: true, if: -> { item_type == "product" }

  before_validation :set_description
  before_validation :calculate_commission
  after_save    :recalculate_attendance
  after_destroy :recalculate_attendance

  def service?
    item_type == "service"
  end

  def product?
    item_type == "product"
  end

  private

  def set_description
    return if description.present?
    self.description = if service?
                         service&.name
    elsif product?
                         product ? "#{product.brand} — #{product.name}" : nil
    end
  end

  def calculate_commission
    return unless price_cents && commission_percent
    self.commission_cents = (price_cents * commission_percent / 100.0).round
  end

  def recalculate_attendance
    attendance.recalculate!
  end
end
