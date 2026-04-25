require "test_helper"

module Api
  module V1
    class AvailabilityControllerTest < ActionDispatch::IntegrationTest
      test "GET disponibilidad devuelve lista de slots JSON" do
        # Lunes 2030-01-07: valentina tiene horario 09:00-18:00
        get api_v1_availability_path,
            params: {
              stylist_id: users(:valentina).id,
              service_id: services(:corte_damas).id,
              date: "2030-01-07"
            }

        assert_response :success
        json = JSON.parse(response.body)
        assert json.key?("slots")
        assert_instance_of Array, json["slots"]
      end

      test "GET disponibilidad devuelve array vacío para día sin horario" do
        # domingo (0) — valentina no tiene horario
        get api_v1_availability_path,
            params: {
              stylist_id: users(:valentina).id,
              service_id: services(:corte_damas).id,
              date: "2030-01-06"  # domingo
            }

        assert_response :success
        json = JSON.parse(response.body)
        assert_empty json["slots"]
      end

      test "GET disponibilidad devuelve 422 con fecha inválida" do
        get api_v1_availability_path,
            params: {
              stylist_id: users(:valentina).id,
              service_id: services(:corte_damas).id,
              date: "no-es-fecha"
            }

        assert_response :unprocessable_entity
      end

      test "GET disponibilidad devuelve 404 con stylist_id inexistente" do
        get api_v1_availability_path,
            params: {
              stylist_id: 999999,
              service_id: services(:corte_damas).id,
              date: "2030-01-07"
            }

        assert_response :not_found
      end
    end
  end
end
