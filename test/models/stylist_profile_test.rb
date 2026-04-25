require "test_helper"

class StylistProfileTest < ActiveSupport::TestCase
  test "válido con atributos correctos" do
    profile = StylistProfile.new(
      stylist: users(:camila),
      commission_percentage: 30
    )
    assert profile.valid?
  end

  test "inválido con commission_percentage mayor a 100" do
    profile = stylist_profiles(:valentina_profile)
    profile.commission_percentage = 101
    assert_not profile.valid?
  end

  test "inválido con commission_percentage negativo" do
    profile = stylist_profiles(:valentina_profile)
    profile.commission_percentage = -1
    assert_not profile.valid?
  end

  test "pertenece a un estilista" do
    profile = stylist_profiles(:valentina_profile)
    assert_equal users(:valentina), profile.stylist
  end
end
