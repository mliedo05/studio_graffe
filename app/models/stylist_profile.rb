class StylistProfile < ApplicationRecord
  belongs_to :stylist, class_name: "User", inverse_of: :stylist_profile

  validates :commission_percentage, numericality: { in: 0..100 }
end
