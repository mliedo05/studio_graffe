class StylistProfile < ApplicationRecord
  belongs_to :stylist, class_name: "User"

  validates :commission_percentage, numericality: { in: 0..100 }
end
