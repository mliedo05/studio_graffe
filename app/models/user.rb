class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

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

  def self.from_omniauth(auth)
    # 1. Buscar por provider+uid (ya vinculado anteriormente)
    user = find_by(provider: auth.provider, uid: auth.uid)

    # 2. Si no existe, buscar por email (cuenta local existente → vincular)
    user ||= find_by(email: auth.info.email)

    # 3. Si no existe por ninguna vía, crear cuenta nueva
    user ||= new

    user.provider   = auth.provider
    user.uid        = auth.uid
    user.email      = auth.info.email
    user.first_name = auth.info.first_name.presence || auth.info.name.split.first
    user.last_name  = auth.info.last_name.presence  || auth.info.name.split.drop(1).join(" ")
    user.avatar_url = auth.info.image
    user.role     ||= "client"

    # Usuarios OAuth nuevos no necesitan contraseña local
    user.password = SecureRandom.hex(16) if user.new_record?

    user.save!
    user
  end

  def oauth_user?
    provider.present?
  end
end
