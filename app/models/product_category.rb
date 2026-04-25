class ProductCategory < ApplicationRecord
  has_many :products, dependent: :destroy

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }

  scope :active,  -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    self.slug ||= name.to_s.parameterize if name.present?
  end
end
