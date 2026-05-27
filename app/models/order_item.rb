class OrderItem < ApplicationRecord
  monetize :unit_price_cents
  monetize :total_price_cents
  monetize :unit_cost_cents,  allow_nil: true
  monetize :total_cost_cents, allow_nil: true

  belongs_to :order
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0 }

  def margin_cents
    return nil if total_cost_cents.nil?
    total_price_cents - total_cost_cents
  end

  def margin_percent
    return nil if total_cost_cents.nil? || total_cost_cents == 0
    ((total_price_cents - total_cost_cents).to_f / total_cost_cents * 100).round(1)
  end
end
