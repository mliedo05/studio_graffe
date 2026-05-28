class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  ROLES = %w[admin stylist client].freeze

  has_one :stylist_profile, foreign_key: :stylist_id, dependent: :destroy
  has_many :stylist_schedules, foreign_key: :stylist_id, dependent: :destroy
  has_many :stylist_blocked_times, foreign_key: :stylist_id, dependent: :destroy
  has_many :appointments_as_client, class_name: "Appointment", foreign_key: :client_id, dependent: :destroy
  has_many :stylist_appointments, class_name: "Appointment", foreign_key: :stylist_id, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :commissions, foreign_key: :stylist_id, dependent: :destroy

  validates :first_name, :last_name, presence: true
  validates :role, inclusion: { in: ROLES }

  scope :admins,   -> { where(role: "admin") }
  scope :stylists, -> { where(role: "stylist") }
  scope :clients,  -> { where(role: "client") }

  def full_name
    "#{first_name} #{last_name}"
  end

  def admin?   = role == "admin"
  def stylist? = role == "stylist"
  def client?  = role == "client"

  def current_cart
    orders.find_or_create_by(status: "cart") do |order|
      order.number = "ORD-#{SecureRandom.hex(4).upcase}"
    end
  end
end
