class AttendanceItem < ApplicationRecord
  belongs_to :attendance
  belongs_to :stylist,          class_name: "User"
  belongs_to :service,          optional: true
  belongs_to :product,          optional: true
  belongs_to :consumed_product, class_name: "Product", optional: true

  monetize :price_cents
  monetize :commission_cents

  ITEM_TYPES  = %w[service product].freeze
  IVA_FACTOR  = 1.19 # IVA Chile 19%

  validates :item_type,          inclusion: { in: ITEM_TYPES }, allow_blank: false
  validates :price_cents,        numericality: { greater_than_or_equal_to: 0 }
  validates :commission_percent, numericality: { in: 0..100 }
  validates :commission_cents,   numericality: { greater_than_or_equal_to: 0 }
  validates :service,            presence: true, if: -> { item_type == "service" }
  validates :product,            presence: true, if: -> { item_type == "product" }
  validates :grams_used,         numericality: { greater_than: 0 }, allow_nil: true
  validates :consumed_product,   presence: true, if: -> { grams_used.present? }

  before_validation :set_description
  before_validation :calculate_product_cost
  before_validation :calculate_commission
  after_save    :recalculate_attendance
  after_destroy :recalculate_attendance

  def service?
    item_type == "service"
  end

  def product?
    item_type == "product"
  end

  # ¿Tiene insumo registrado?
  def uses_insumo?
    consumed_product_id.present? && grams_used.to_f > 0
  end

  # Precio sin IVA (base imponible)
  def net_price_cents
    (price_cents / IVA_FACTOR).round
  end

  # IVA incluido en el precio
  def iva_cents
    price_cents - net_price_cents
  end

  # Base comisionable = neto - costo insumo
  def commissionable_cents
    [ net_price_cents - product_cost_cents.to_i, 0 ].max
  end

  # Parte del estudio luego de descontar la comisión (sobre base comisionable)
  def studio_cents
    commissionable_cents - commission_cents
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

  def calculate_product_cost
    if consumed_product && grams_used.to_f > 0
      self.product_cost_cents = (grams_used.to_f * consumed_product.cost_per_gram_cents).round
    else
      self.product_cost_cents = 0
    end
  end

  def calculate_commission
    return unless price_cents && commission_percent
    # Comisión sobre base comisionable (neto - costo insumo)
    self.commission_cents = (commissionable_cents * commission_percent / 100.0).round
  end

  def recalculate_attendance
    attendance.recalculate!
  end
end
