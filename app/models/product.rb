class Product < ApplicationRecord
  monetize :price_cents

  belongs_to :product_category
  has_many :order_items, dependent: :restrict_with_error
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

  private

  def generate_slug
    self.slug ||= "#{brand}-#{name}".parameterize if brand.present? && name.present?
  end
end
