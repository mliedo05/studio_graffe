module ApplicationHelper
  include Pagy::Frontend

  def price_clp(cents)
    number_to_currency(cents, unit: "$", delimiter: ".", separator: ",", precision: 0)
  end
end
