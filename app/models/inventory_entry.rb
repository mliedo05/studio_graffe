class InventoryEntry < ApplicationRecord
  belongs_to :product

  monetize :unit_cost_cents

  validates :quantity_received,  numericality: { greater_than: 0 }
  validates :quantity_remaining, numericality: { greater_than_or_equal_to: 0 }
  validates :unit_cost_cents,    numericality: { greater_than: 0 }
  validates :supplier,           presence: true
  validates :invoice_number,     presence: true
  validates :received_at,        presence: true

  # Lotes disponibles más antiguos primero (FIFO)
  scope :available, -> { where("quantity_remaining > 0").order(:received_at, :id) }

  before_validation :set_quantity_remaining, on: :create

  def fully_consumed?
    quantity_remaining == 0
  end

  def unit_cost
    Money.new(unit_cost_cents, "CLP")
  end

  private

  def set_quantity_remaining
    self.quantity_remaining = quantity_received if quantity_remaining.nil?
  end
end
