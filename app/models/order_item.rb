class OrderItem < ApplicationRecord
  monetize :unit_price_cents
  monetize :total_price_cents

  belongs_to :order
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0 }
end
