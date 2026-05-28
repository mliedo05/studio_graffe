module Supervisor
  class CajaController < BaseController
    def index
      range = period_range

      # ── Desglose de pagos REALES por método ─────────────────────────
      @by_method = AttendancePayment
        .real
        .joins(:attendance)
        .where(attendances: { attended_on: range })
        .group(:payment_method)
        .sum(:amount_cents)

      @total_cobrado_cents = @by_method.values.sum

      # ── Atenciones con saldo pendiente en el período ─────────────────
      @pending_attendances = Attendance
        .includes(:client, :attendance_items, :attendance_payments)
        .where(attended_on: range)
        .where("total_cents > paid_cents")
        .order(attended_on: :desc, number: :desc)

      @total_pendiente_cents = @pending_attendances.sum(&:balance_cents)

      # ── Log completo de pagos del período (para conciliación) ─────────
      @payments = AttendancePayment
        .includes(attendance: :client)
        .joins(:attendance)
        .where(attendances: { attended_on: range })
        .order("attendances.attended_on DESC, attendance_payments.created_at DESC")
    end

    def registrar_pago
      attendance = Attendance.find(params[:attendance_id])
      payment = attendance.attendance_payments.build(
        payment_method: params[:payment_method],
        amount_cents:   params[:amount_cents].to_s.gsub(/\D/, "").to_i,
        note:           params[:note]
      )

      if payment.save
        redirect_to supervisor_caja_path(period: params[:period], from: params[:from], to: params[:to]),
                    notice: "Pago registrado correctamente."
      else
        redirect_to supervisor_caja_path(period: params[:period], from: params[:from], to: params[:to]),
                    alert: "Error: #{payment.errors.full_messages.join(", ")}"
      end
    end
  end
end
