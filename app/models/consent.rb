class Consent < ApplicationRecord
  enum document_type: { rut: 0, passport: 1, other: 2 }

  validates :first_name, :last_name, :email, :document_number, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  has_one_attached :signature

end
