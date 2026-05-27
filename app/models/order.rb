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
  def checkout?  = status == "checkout"
  def paid?      = status == "paid"
  def cancelled? = status == "cancelled"

  scope :completed, -> { where.not(status: %w[cart cancelled]) }
  scope :visible,   -> { where.not(status: "cart") }

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

  # Cancels a checkout-in-progress order after a failed payment.
  # Creates a fresh cart for the user, copying all items so they don't lose their selection.
  def cancel_failed_payment!
    raise InvalidTransitionError, "Solo órdenes en checkout pueden cancelarse por pago fallido." unless status == "checkout"

    # Load items BEFORE the update! call to avoid association cache issues
    items_snapshot = order_items.to_a

    transaction do
      update!(status: "cancelled", payment_status: "failed")

      # Re-use existing cart or create one — never create duplicates
      cart = user.current_cart
      items_snapshot.each do |item|
        existing = cart.order_items.find_by(product_id: item.product_id)
        if existing
          existing.update!(
            quantity:          existing.quantity + item.quantity,
            total_price_cents: existing.unit_price_cents * (existing.quantity + item.quantity)
          )
        else
          cart.order_items.create!(
            product_id:        item.product_id,
            quantity:          item.quantity,
            unit_price_cents:  item.unit_price_cents,
            total_price_cents: item.total_price_cents
          )
        end
      end
      cart.recalculate!
    end
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
      consume_fifo!(item)
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

  class EmptyCartError         < StandardError; end
  class InvalidTransitionError < StandardError; end
  class OutOfStockError        < StandardError; end

  private

  # Consume inventory entries FIFO for one order item and records unit cost.
  # If no inventory entries exist (e.g. legacy products), records cost as 0.
  def consume_fifo!(item)
    qty_needed   = item.quantity
    total_cost   = 0

    item.product.inventory_entries.available.each do |entry|
      break if qty_needed == 0

      consume = [ entry.quantity_remaining, qty_needed ].min
      total_cost  += consume * entry.unit_cost_cents
      qty_needed  -= consume
      entry.update!(quantity_remaining: entry.quantity_remaining - consume)
    end

    # qty_needed > 0 means stock was sold without inventory entries (legacy)
    unit_cost  = item.quantity > 0 ? total_cost / item.quantity : 0
    item.update!(
      unit_cost_cents:  unit_cost,
      total_cost_cents: total_cost
    )
  end
end
