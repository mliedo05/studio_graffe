require "test_helper"

class SupervisorAttendancesControllerTest < ActionDispatch::IntegrationTest
  # ── Acceso general ────────────────────────────────────────────────

  test "usuario no autenticado es redirigido al login" do
    get supervisor_attendances_path
    assert_redirected_to new_user_session_path
  end

  test "cliente no puede acceder al área supervisor" do
    sign_in_as(users(:cliente))
    get supervisor_attendances_path
    assert_redirected_to root_path
  end

  test "estilista no puede acceder al área supervisor" do
    sign_in_as(users(:valentina))
    get supervisor_attendances_path
    assert_redirected_to root_path
  end

  test "admin puede acceder al área supervisor" do
    sign_in_as(users(:admin))
    get supervisor_attendances_path
    assert_response :success
  end

  # ── index ─────────────────────────────────────────────────────────

  test "index lista atenciones del período" do
    sign_in_as(users(:admin))
    get supervisor_attendances_path(period: "custom", from: "2026-01-01", to: "2026-01-31")
    assert_response :success
    assert_match attendances(:atencion_cerrada).number, response.body
  end

  test "index responde con período por defecto" do
    sign_in_as(users(:admin))
    get supervisor_attendances_path
    assert_response :success
  end

  # ── show ──────────────────────────────────────────────────────────

  test "show muestra detalle de una atención" do
    sign_in_as(users(:admin))
    get supervisor_attendance_path(attendances(:atencion_cerrada))
    assert_response :success
    assert_match attendances(:atencion_cerrada).number, response.body
  end

  test "show muestra insumo cuando está registrado" do
    sign_in_as(users(:admin))
    # Crear atención con insumo para verificar que aparece en la vista
    attendance = Attendance.create!(
      attended_on:   Date.current,
      registered_by: users(:admin),
      client:        users(:cliente),
      status:        "closed"
    )
    attendance.attendance_items.create!(
      item_type:           "service",
      service:             services(:corte_damas),
      stylist:             users(:valentina),
      price_cents:         119000,
      commission_percent:  40,
      consumed_product:    products(:tinte_insumo),
      grams_used:          15,
      stock_deducted:      true
    )
    get supervisor_attendance_path(attendance)
    assert_response :success
    assert_match products(:tinte_insumo).name, response.body
  end

  # ── new ───────────────────────────────────────────────────────────

  test "new renderiza formulario de nueva atención" do
    sign_in_as(users(:admin))
    get new_supervisor_attendance_path
    assert_response :success
    assert_select "form"
  end

  # ── create ────────────────────────────────────────────────────────

  test "create crea atención con servicio e insumo" do
    sign_in_as(users(:admin))
    assert_difference "Attendance.count", 1 do
      post supervisor_attendances_path, params: {
        attendance: {
          attended_on: Date.current.to_s,
          client_id:   users(:cliente).id,
          attendance_items_attributes: {
            "0" => {
              item_type:           "service",
              service_id:          services(:corte_damas).id,
              stylist_id:          users(:valentina).id,
              price_cents:         119000,
              commission_percent:  40,
              consumed_product_id: products(:tinte_insumo).id,
              grams_used:          15
            }
          },
          attendance_payments_attributes: {
            "0" => { payment_method: "cash", amount_cents: 119000 }
          }
        }
      }
    end
    attendance = Attendance.order(:created_at).last
    assert_redirected_to supervisor_attendance_path(attendance)
    item = attendance.attendance_items.first
    assert_equal products(:tinte_insumo).id, item.consumed_product_id
    assert_equal 15, item.grams_used.to_i
    # commission = (119000/1.19 × 40%) - (15 × 680) = 40000 - 10200 = 29800
    assert_equal 29800, item.commission_cents
  end

  test "create sin cliente falla y renderiza :new" do
    sign_in_as(users(:admin))
    assert_no_difference "Attendance.count" do
      post supervisor_attendances_path, params: {
        attendance: {
          attended_on: Date.current.to_s,
          client_id:   "",
          attendance_items_attributes: {
            "0" => {
              item_type: "service", service_id: services(:corte_damas).id,
              stylist_id: users(:valentina).id, price_cents: 50000, commission_percent: 40
            }
          },
          attendance_payments_attributes: {
            "0" => { payment_method: "cash", amount_cents: 50000 }
          }
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "create descuenta stock del producto vendido" do
    sign_in_as(users(:admin))
    product = products(:shampoo_wella)
    before  = product.stock_quantity

    post supervisor_attendances_path, params: {
      attendance: {
        attended_on: Date.current.to_s,
        client_id:   users(:cliente).id,
        attendance_items_attributes: {
          "0" => {
            item_type: "product", product_id: product.id,
            stylist_id: users(:valentina).id, price_cents: 18990, commission_percent: 10
          }
        },
        attendance_payments_attributes: {
          "0" => { payment_method: "cash", amount_cents: 18990 }
        }
      }
    }
    assert_equal before - 1, product.reload.stock_quantity
  end

  # ── edit / update ─────────────────────────────────────────────────

  test "edit renderiza formulario de edición" do
    sign_in_as(users(:admin))
    get edit_supervisor_attendance_path(attendances(:atencion_pendiente))
    assert_response :success
    assert_select "form"
  end

  test "update modifica los datos de la atención" do
    sign_in_as(users(:admin))
    attendance = attendances(:atencion_pendiente)
    patch supervisor_attendance_path(attendance), params: {
      attendance: { notes: "Nota actualizada desde test" }
    }
    assert_redirected_to supervisor_attendance_path(attendance)
    assert_equal "Nota actualizada desde test", attendance.reload.notes
  end

  test "update con insumo actualiza consumed_product_id y grams_used" do
    sign_in_as(users(:admin))
    attendance = attendances(:atencion_pendiente)
    item       = attendance.attendance_items.first

    patch supervisor_attendance_path(attendance), params: {
      attendance: {
        attendance_items_attributes: {
          "0" => {
            id:                  item.id,
            consumed_product_id: products(:tinte_insumo).id,
            grams_used:          20
          }
        }
      }
    }
    assert_redirected_to supervisor_attendance_path(attendance)
    item.reload
    assert_equal products(:tinte_insumo).id, item.consumed_product_id
    assert_equal 20, item.grams_used.to_i
  end

  # ── close ─────────────────────────────────────────────────────────

  test "close cambia estado a closed" do
    sign_in_as(users(:admin))
    attendance = attendances(:atencion_pendiente)
    patch close_supervisor_attendance_path(attendance)
    assert_redirected_to supervisor_attendance_path(attendance)
    assert_equal "closed", attendance.reload.status
  end

  test "close descuenta insumos con deduct_insumo_stock!" do
    sign_in_as(users(:admin))
    insumo = products(:tinte_insumo)
    before = insumo.stock_quantity

    attendance = Attendance.create!(
      attended_on:   Date.current,
      registered_by: users(:admin),
      client:        users(:cliente),
      status:        "open"
    )
    attendance.attendance_items.create!(
      item_type:           "service",
      service:             services(:corte_damas),
      stylist:             users(:valentina),
      price_cents:         119000,
      commission_percent:  40,
      consumed_product:    insumo,
      grams_used:          10,
      stock_deducted:      false
    )

    patch close_supervisor_attendance_path(attendance)
    assert_equal before - 10, insumo.reload.stock_quantity
  end

  # ── search_client ─────────────────────────────────────────────────

  test "search_client devuelve JSON con clientes que coincidan" do
    sign_in_as(users(:admin))
    get search_client_supervisor_attendances_path, params: { q: users(:cliente).first_name }
    assert_response :success
    json = JSON.parse(response.body)
    assert_kind_of Array, json
    assert json.any? { |u| u["id"] == users(:cliente).id }
  end

  test "search_client devuelve arreglo vacío para query sin matches" do
    sign_in_as(users(:admin))
    get search_client_supervisor_attendances_path, params: { q: "xzxzxzx_no_existe" }
    json = JSON.parse(response.body)
    assert_empty json
  end

  # ── create_client ─────────────────────────────────────────────────

  test "create_client crea un nuevo usuario cliente" do
    sign_in_as(users(:admin))
    assert_difference "User.count", 1 do
      post create_client_supervisor_attendances_path, params: {
        first_name: "Paulina",
        last_name:  "Rojas",
        email:      "paulina.rojas.test@example.com"
      }
    end
    json = JSON.parse(response.body)
    assert_equal "Paulina Rojas", json["name"]
    assert_not json["existing"]
  end

  test "create_client retorna usuario existente si el email ya está registrado" do
    sign_in_as(users(:admin))
    assert_no_difference "User.count" do
      post create_client_supervisor_attendances_path, params: {
        first_name: "Nuevo",
        last_name:  "Nombre",
        email:      users(:cliente).email
      }
    end
    json = JSON.parse(response.body)
    assert json["existing"]
    assert_equal users(:cliente).id, json["id"]
  end

  test "create_client retorna errores con email inválido" do
    sign_in_as(users(:admin))
    assert_no_difference "User.count" do
      post create_client_supervisor_attendances_path, params: {
        first_name: "Sin",
        last_name:  "Email",
        email:      "no-es-un-email"
      }
    end
    json = JSON.parse(response.body)
    assert json["errors"].present?
  end

  # ── destroy ──────────────────────────────────────────────────────

  test "usuario no autenticado no puede eliminar" do
    delete supervisor_attendance_path(attendances(:atencion_cerrada))
    assert_redirected_to new_user_session_path
  end

  test "cliente no puede eliminar atenciones" do
    sign_in_as(users(:cliente))
    delete supervisor_attendance_path(attendances(:atencion_cerrada))
    assert_redirected_to root_path
  end

  test "admin puede eliminar una atención" do
    sign_in_as(users(:admin))
    attendance = attendances(:atencion_pendiente)
    assert_difference "Attendance.count", -1 do
      delete supervisor_attendance_path(attendance)
    end
    assert_redirected_to supervisor_attendances_path
    assert_match "eliminada", flash[:notice]
  end

  test "eliminar atención restaura stock del producto vendido" do
    sign_in_as(users(:admin))
    product = products(:shampoo_wella)
    before  = product.stock_quantity

    attendance = Attendance.create!(
      attended_on:   Date.current,
      registered_by: users(:admin),
      client:        users(:cliente),
      status:        "open"
    )
    attendance.attendance_items.create!(
      item_type:          "product",
      product:            product,
      stylist:            users(:valentina),
      price_cents:        18990,
      commission_percent: 10
    )

    delete supervisor_attendance_path(attendance)
    assert_equal before + 1, product.reload.stock_quantity
  end

  test "eliminar atención restaura gramos de insumo si stock_deducted = true" do
    sign_in_as(users(:admin))
    insumo = products(:tinte_insumo)
    before = insumo.stock_quantity

    attendance = Attendance.create!(
      attended_on:   Date.current,
      registered_by: users(:admin),
      client:        users(:cliente),
      status:        "closed"
    )
    attendance.attendance_items.create!(
      item_type:           "service",
      service:             services(:corte_damas),
      stylist:             users(:valentina),
      price_cents:         119000,
      commission_percent:  40,
      consumed_product:    products(:tinte_insumo),
      grams_used:          20,
      stock_deducted:      true
    )

    delete supervisor_attendance_path(attendance)
    assert_equal before + 20, insumo.reload.stock_quantity
  end

  test "eliminar atención destruye sus ítems y pagos en cascada" do
    sign_in_as(users(:admin))
    attendance = attendances(:atencion_cerrada)

    item_ids    = attendance.attendance_items.pluck(:id)
    payment_ids = attendance.attendance_payments.pluck(:id)

    delete supervisor_attendance_path(attendance)

    assert_empty AttendanceItem.where(id: item_ids)
    assert_empty AttendancePayment.where(id: payment_ids)
  end
end
