class Attendance < ApplicationRecord
  belongs_to :client,        class_name: "User", optional: true
  belongs_to :registered_by, class_name: "User"
  has_many   :attendance_items,    dependent: :destroy
  has_many   :attendance_payments, dependent: :destroy

  accepts_nested_attributes_for :attendance_items,    allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :attendance_payments, allow_destroy: true, reject_if: :all_blank

  monetize :total_cents
  monetize :paid_cents

  STATUSES       = %w[open closed].freeze
  ITEM_TYPES     = %w[service product].freeze

  validates :number,      presence: true, uniqueness: true
  validates :attended_on, presence: true
  validates :status,      inclusion: { in: STATUSES }
  validates :client,      presence: { message: "debe seleccionarse una clienta" }
  validates :client_name, presence: true, if: -> { client.nil? }

  before_validation :set_number, on: :create

  scope :by_date,     ->(date) { where(attended_on: date) }
  scope :this_month,  -> { where(attended_on: Time.current.beginning_of_month..Time.current.end_of_month) }
  scope :ordered,     -> { order(attended_on: :desc, number: :desc) }

  # ── Número correlativo: 20260528-001 ─────────────────────────────
  def self.next_number_for(date)
    prefix = date.strftime("%Y%m%d")
    last   = where("number LIKE ?", "#{prefix}-%").order(:number).last
    seq    = last ? last.number.split("-").last.to_i + 1 : 1
    "#{prefix}-#{seq.to_s.rjust(3, "0")}"
  end

  # ── Nombre del cliente (registrado o walk-in) ────────────────────
  def display_client_name
    client&.full_name.presence || client_name.presence || "Sin nombre"
  end

  # ── Recalcula totales desde los ítems y pagos ────────────────────
  def recalculate!
    new_total = attendance_items.sum(:price_cents)
    # Los pagos "pending" no cuentan como cobrado
    new_paid  = attendance_payments.real.sum(:amount_cents)
    update_columns(total_cents: new_total, paid_cents: new_paid)
  end

  def pending_cents
    balance_cents
  end

  def fully_paid?
    balance_cents <= 0
  end

  def partially_paid?
    paid_cents > 0 && balance_cents > 0
  end

  # ── Balance pendiente ─────────────────────────────────────────────
  def balance_cents
    total_cents - paid_cents
  end

  # ── Total comisiones ──────────────────────────────────────────────
  def total_commission_cents
    attendance_items.sum(:commission_cents)
  end

  # Descuenta los gramos usados del stock de cada insumo (solo al cerrar)
  # Idempotente: solo descuenta ítems donde stock_deducted = false
  def deduct_insumo_stock!
    attendance_items
      .where.not(consumed_product_id: nil)
      .where(stock_deducted: false)
      .each do |item|
        next unless item.grams_used.to_f > 0

        product = item.consumed_product
        grams   = item.grams_used.to_f.ceil   # redondea hacia arriba

        Product.where(id: product.id)
               .update_all("stock_quantity = GREATEST(stock_quantity - #{grams}, 0)")
        item.update_column(:stock_deducted, true)
      end
  end

  private

  def set_number
    self.number ||= self.class.next_number_for(attended_on || Date.current)
  end
end
