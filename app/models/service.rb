class Service < ApplicationRecord
  monetize :price_cents

  has_many :appointments, dependent: :restrict_with_error

  validates :name, :category, presence: true
  validates :duration_minutes, numericality: { greater_than: 0 }
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }

  scope :active,  -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }
end
