module Supervisor
  class AttendancesController < BaseController
    before_action :set_attendance, only: [ :show, :edit, :update, :close ]

    def index
      range = period_range
      @q = Attendance.where(attended_on: range).ransack(params[:q])
      @pagy, @attendances = pagy(@q.result.includes(:attendance_items, :attendance_payments).ordered, items: 50)
    end

    def show
      @items    = @attendance.attendance_items.includes(:stylist, :service, :product)
      @payments = @attendance.attendance_payments
    end

    def new
      @attendance = Attendance.new(attended_on: Date.current)
      @attendance.attendance_items.build
      @attendance.attendance_payments.build
    end

    def create
      @attendance = Attendance.new(attendance_params)
      @attendance.registered_by = current_user

      if @attendance.save
        # Descontar inventario de productos vendidos
        discount_product_stock(@attendance)
        redirect_to supervisor_attendance_path(@attendance),
                    notice: "Atención #{@attendance.number} registrada correctamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @attendance.update(attendance_params)
        redirect_to supervisor_attendance_path(@attendance),
                    notice: "Atención actualizada."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def close
      @attendance.update!(status: "closed")
      redirect_to supervisor_attendance_path(@attendance), notice: "Atención cerrada."
    end

    # GET /supervisor/atenciones/search_client?q=Juan
    def search_client
      query = params[:q].to_s.strip
      @users = User.clients
                   .where("first_name ILIKE :q OR last_name ILIKE :q OR email ILIKE :q", q: "%#{query}%")
                   .limit(10)
      render json: @users.map { |u| { id: u.id, name: u.full_name, email: u.email } }
    end

    # POST /supervisor/atenciones/create_client
    # Crea un cliente nuevo desde el modal del formulario de atención.
    # Si el email ya existe, retorna el usuario existente (para cuando
    # el cliente ya tiene cuenta y quiere asociarse).
    def create_client
      existing = User.find_by(email: params[:email].to_s.strip.downcase)

      if existing
        render json: { id: existing.id, name: existing.full_name, email: existing.email, existing: true }
        return
      end

      user = User.new(
        first_name: params[:first_name],
        last_name:  params[:last_name],
        email:      params[:email].to_s.strip.downcase,
        phone:      params[:phone],
        role:       "client",
        walk_in:    true,
        password:   SecureRandom.hex(12)   # contraseña temporal — recupera acceso vía email
      )

      if user.save
        render json: { id: user.id, name: user.full_name, email: user.email, existing: false }
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def set_attendance
      @attendance = Attendance.find(params[:id])
    end

    def attendance_params
      params.require(:attendance).permit(
        :attended_on, :client_id, :client_name, :notes, :status,
        attendance_items_attributes: [
          :id, :item_type, :service_id, :product_id, :description,
          :stylist_id, :price_cents, :commission_percent, :_destroy
        ],
        attendance_payments_attributes: [
          :id, :payment_method, :amount_cents, :note, :_destroy
        ]
      )
    end

    def discount_product_stock(attendance)
      attendance.attendance_items.where(item_type: "product").each do |item|
        next unless item.product
        item.product.decrement!(:stock_quantity)
      end
    end
  end
end
