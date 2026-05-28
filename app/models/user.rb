class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  ROLES = %w[admin supervisor stylist client].freeze

  has_one :stylist_profile, foreign_key: :stylist_id, dependent: :destroy
  has_many :stylist_schedules, foreign_key: :stylist_id, dependent: :destroy
  has_many :stylist_blocked_times, foreign_key: :stylist_id, dependent: :destroy
  has_many :appointments_as_client, class_name: "Appointment", foreign_key: :client_id, dependent: :destroy
  has_many :stylist_appointments, class_name: "Appointment", foreign_key: :stylist_id, dependent: :destroy
  has_many :orders,    dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_many :commissions, foreign_key: :stylist_id, dependent: :destroy

  # Attendance associations
  has_many :attendances_as_client,      class_name: "Attendance", foreign_key: :client_id, dependent: :nullify
  has_many :attendances_registered,     class_name: "Attendance", foreign_key: :registered_by_id, dependent: :restrict_with_error
  has_many :attendance_items_as_stylist, class_name: "AttendanceItem", foreign_key: :stylist_id, dependent: :restrict_with_error

  validates :first_name, :last_name, presence: true
  validates :role, inclusion: { in: ROLES }

  scope :admins,      -> { where(role: "admin") }
  scope :supervisors, -> { where(role: "supervisor") }
  scope :stylists,    -> { where(role: "stylist") }
  scope :clients,     -> { where(role: "client") }
  scope :staff,       -> { where(role: %w[admin supervisor stylist]) }
  scope :walk_ins,    -> { where(walk_in: true) }

  def full_name
    "#{first_name} #{last_name}"
  end

  def admin?      = role == "admin"
  def supervisor? = role == "supervisor"
  def stylist?    = role == "stylist"
  def client?     = role == "client"
  def staff?      = admin? || supervisor? || stylist?

  def current_cart
    # Always use the most recent cart; if somehow multiple exist, collapse them
    existing = orders.where(status: "cart").order(:created_at).last
    return existing if existing

    orders.create!(
      number:         "ORD-#{SecureRandom.hex(4).upcase}",
      status:         "cart",
      payment_status: "pending",
      subtotal_cents: 0,
      total_cents:    0
    )
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

  def self.ransackable_attributes(auth_object = nil)
    %w[first_name last_name email role created_at id]
  end
end
