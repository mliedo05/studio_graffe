class Order < ApplicationRecord
  monetize :subtotal_cents
  monetize :total_cents

  belongs_to :user
  has_many :order_items, dependent: :destroy

  STATUSES         = %w[cart checkout paid shipped delivered cancelled].freeze
  PAYMENT_STATUSES = %w[pending paid failed refunded].freeze
  SHIPPING_TYPES   = %w[pickup delivery].freeze
  DOCUMENT_TYPES   = %w[rut passport dni].freeze

  validates :number, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :payment_status, inclusion: { in: PAYMENT_STATUSES }
  validates :shipping_type, inclusion: { in: SHIPPING_TYPES }, allow_nil: true
  validates :billing_document_type, inclusion: { in: DOCUMENT_TYPES }, allow_nil: true

  validates :billing_first_name, :billing_last_name, :billing_document_type,
            :billing_document_number, :billing_email, :billing_phone,
            presence: true, if: :checkout?

  validates :shipping_region, :shipping_comuna, :shipping_city,
            :shipping_street, :shipping_street_number,
            :shipping_recipient_name, :shipping_phone,
            presence: true, if: -> { checkout? && delivery? }

  def pickup?   = shipping_type == "pickup"
  def delivery? = shipping_type == "delivery"
  def checkout? = status == "checkout"

  scope :completed, -> { where.not(status: %w[cart cancelled]) }

  def item_count
    order_items.sum(:quantity)
  end

  def recalculate!
    subtotal = order_items.reload.sum("unit_price_cents * quantity")
    update!(subtotal_cents: subtotal, total_cents: subtotal)
  end

  def checkout!
    raise EmptyCartError, "El carrito está vacío." if order_items.empty?
    raise InvalidTransitionError, "Solo un carrito activo puede pasar a checkout." unless status == "cart"
    update!(status: "checkout")
  end

  def mark_paid!(transaction_id:, payment_method:)
    raise InvalidTransitionError, "Solo órdenes en checkout pueden marcarse como pagadas." unless status == "checkout"

    update!(
      status: "paid",
      payment_status: "paid",
      transaction_id: transaction_id,
      payment_method: payment_method
    )
    order_items.each do |item|
      item.product.decrement!(:stock_quantity, item.quantity)
    end
  end

  def add_product!(product, quantity = 1)
    raise ArgumentError, "La cantidad debe ser mayor a 0." unless quantity.to_i > 0
    raise OutOfStockError, "#{product.name} no tiene suficiente stock." if product.stock_quantity < quantity.to_i

    item = order_items.find_or_initialize_by(product: product)
    new_quantity = (item.new_record? ? 0 : item.quantity) + quantity.to_i

    raise OutOfStockError, "No hay suficiente stock de #{product.name}." if new_quantity > product.stock_quantity

    item.unit_price_cents  = product.price_cents
    item.quantity          = new_quantity
    item.total_price_cents = item.unit_price_cents * item.quantity
    item.save!
    recalculate!
  end

  def remove_product!(product)
    order_items.find_by(product: product)&.destroy
    recalculate!
  end

  class EmptyCartError        < StandardError; end
  class InvalidTransitionError < StandardError; end
  class OutOfStockError       < StandardError; end
end
