class Product < ApplicationRecord
  monetize :price_cents

  belongs_to :product_category
  has_many :order_items,       dependent: :restrict_with_error
  has_many :inventory_entries, dependent: :destroy
  has_one_attached :image

  validates :name, :brand, :slug, presence: true
  validates :slug, uniqueness: true
  validates :name, uniqueness: { scope: :brand, message: "ya existe un producto con ese nombre y marca" }
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }

  scope :active,    -> { where(active: true) }
  scope :featured,  -> { where(featured: true) }
  scope :in_stock,  -> { where("stock_quantity > 0") }
  scope :ordered,   -> { order(:position, :name) }

  before_validation :generate_slug, on: :create

  def in_stock?
    stock_quantity > 0
  end

  # Carga mercadería: crea el lote y actualiza stock visible
  def receive_stock!(quantity:, unit_cost_cents:, supplier:, invoice_number:, received_at: Time.current, notes: nil)
    transaction do
      entry = inventory_entries.create!(
        quantity_received:  quantity,
        quantity_remaining: quantity,
        unit_cost_cents:    unit_cost_cents,
        supplier:           supplier,
        invoice_number:     invoice_number,
        received_at:        received_at,
        notes:              notes
      )
      increment!(:stock_quantity, quantity)
      entry
    end
  end

  # Costo promedio ponderado de los lotes disponibles (para referencia)
  def weighted_average_cost
    entries = inventory_entries.available
    total_units = entries.sum(:quantity_remaining)
    return Money.new(0, "CLP") if total_units == 0

    total_cost = entries.sum("quantity_remaining * unit_cost_cents")
    Money.new(total_cost / total_units, "CLP")
  end

  private

  def generate_slug
    self.slug ||= "#{brand}-#{name}".parameterize if brand.present? && name.present?
  end
end
