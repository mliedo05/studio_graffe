class AttendanceItem < ApplicationRecord
  belongs_to :attendance
  belongs_to :stylist,  class_name: "User"
  belongs_to :service,  optional: true
  belongs_to :product,  optional: true

  monetize :price_cents
  monetize :commission_cents

  ITEM_TYPES  = %w[service product].freeze
  IVA_FACTOR  = 1.19 # IVA Chile 19%

  validates :item_type,          inclusion: { in: ITEM_TYPES }, allow_blank: false
  # description se auto-llena desde el nombre del servicio/producto en set_description
  validates :price_cents,        numericality: { greater_than_or_equal_to: 0 }
  validates :commission_percent, numericality: { in: 0..100 }
  validates :commission_cents,   numericality: { greater_than_or_equal_to: 0 }
  validates :service,            presence: true, if: -> { item_type == "service" }
  validates :product,            presence: true, if: -> { item_type == "product" }

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

  # Precio sin IVA (base imponible para el cálculo de comisión)
  def net_price_cents
    (price_cents / IVA_FACTOR).round
  end

  # IVA incluido en el precio
  def iva_cents
    price_cents - net_price_cents
  end

  # Parte del estudio luego de descontar la comisión (sobre neto)
  def studio_cents
    net_price_cents - commission_cents
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
    # La comisión se calcula sobre el precio NETO (sin IVA)
    self.commission_cents = (net_price_cents * commission_percent / 100.0).round
  end

  def recalculate_attendance
    attendance.recalculate!
  end
end
