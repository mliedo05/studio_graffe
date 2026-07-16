require "test_helper"

class Supervisor::Attendances::TechnicalSheetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @attendance    = attendances(:atencion_cerrada)
    @supervisor    = users(:supervisor)
    @admin         = users(:admin)
    @client_user   = users(:cliente)
  end

  # ── Acceso ────────────────────────────────────────────────────────

  test "sin sesión redirige a login" do
    get edit_supervisor_technical_sheet_path(@attendance)
    assert_redirected_to new_user_session_path
  end

  test "cliente no puede acceder" do
    sign_in_as @client_user
    get edit_supervisor_technical_sheet_path(@attendance)
    assert_response :redirect
    assert_not_equal edit_supervisor_technical_sheet_path(@attendance), response.location
  end

  test "supervisor puede ver formulario de ficha técnica" do
    sign_in_as @supervisor
    get edit_supervisor_technical_sheet_path(@attendance)
    assert_response :success
    assert_select "form"
  end

  test "admin puede ver formulario de ficha técnica" do
    sign_in_as @admin
    get edit_supervisor_technical_sheet_path(@attendance)
    assert_response :success
  end

  # ── Crear ficha técnica ────────────────────────────────────────────

  test "supervisor puede crear ficha técnica" do
    sign_in_as @supervisor
    attendance_sin_ficha = attendances(:atencion_pendiente)
    assert_nil attendance_sin_ficha.technical_sheet

    patch supervisor_technical_sheet_path(attendance_sin_ficha), params: {
      attendance_technical_sheet: {
        technique: "baño_de_color",
        tint_brand: "L'Oréal",
        tint_formula: "5.3 + 20vol",
        decolorization_applied: false,
        hair_elasticity: "bien",
        hair_porosity: "normal",
        notes: "Primera visita"
      }
    }

    assert_redirected_to supervisor_attendance_path(attendance_sin_ficha)
    attendance_sin_ficha.reload
    assert_not_nil attendance_sin_ficha.technical_sheet
    assert_equal "baño_de_color", attendance_sin_ficha.technical_sheet.technique
    assert_equal "L'Oréal", attendance_sin_ficha.technical_sheet.tint_brand
  end

  # ── Actualizar ficha técnica ───────────────────────────────────────

  test "supervisor puede actualizar ficha técnica existente" do
    sign_in_as @supervisor
    sheet = attendance_technical_sheets(:ficha_balayage)

    patch supervisor_technical_sheet_path(@attendance), params: {
      attendance_technical_sheet: {
        technique: "balayage",
        tint_brand: "Wella",
        tint_formula: "9.1 + Blondor 60gr",
        decolorization_applied: true,
        decolorization_height: "largo_total",
        decolorization_level_start: 5,
        decolorization_level_achieved: 10,
        hair_elasticity: "leve",
        hair_porosity: "alta",
        notes: "Segunda visita, cabello más seco"
      }
    }

    assert_redirected_to supervisor_attendance_path(@attendance)
    sheet.reload
    assert_equal "largo_total", sheet.decolorization_height
    assert_equal 10, sheet.decolorization_level_achieved
    assert_equal "leve", sheet.hair_elasticity
  end

  # ── Vista del show de atención ─────────────────────────────────────

  test "show de atención muestra enlace a ficha técnica" do
    sign_in_as @supervisor
    get supervisor_attendance_path(@attendance)
    assert_response :success
    assert_select "a[href='#{edit_supervisor_technical_sheet_path(@attendance)}']"
  end

  test "show de atención muestra datos de ficha técnica existente" do
    sign_in_as @supervisor
    get supervisor_attendance_path(@attendance)
    assert_response :success
    assert_match "Balayage", response.body
    assert_match "Wella", response.body
  end
end
