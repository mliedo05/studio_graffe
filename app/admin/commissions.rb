ActiveAdmin.register Commission do
  actions :index, :show

  index do
    selectable_column
    id_column
    column(:estilista) { |c| c.stylist.full_name }
    column(:cita) { |c| c.appointment.number }
    column(:monto) { |c| number_to_currency(c.amount_cents, unit: "$", delimiter: ".", precision: 0) }
    column(:porcentaje) { |c| "#{c.percentage}%" }
    column :status
    column :paid_at
    actions
  end

  filter :status
  filter :stylist_id, as: :select, collection: -> { User.stylists.map { |u| [ u.full_name, u.id ] } }

  action_item :pay, only: :show do
    link_to "Marcar como Pagada", pay_admin_commission_path(commission), method: :put if commission.status == "pending"
  end

  member_action :pay, method: :put do
    resource.pay!
    redirect_to admin_commissions_path, notice: "Comisión marcada como pagada."
  end
end
