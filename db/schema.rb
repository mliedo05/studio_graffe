# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2025_01_07_201513) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "consents", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.integer "document_type"
    t.string "document_number"
    t.string "phone_number"
    t.text "professional_diagnosis"
    t.text "professional_observations"
    t.boolean "procedure_authorization"
    t.boolean "procedure_acknowledgement"
    t.boolean "diagnosis_confirmation"
    t.boolean "image_use_authorization"
    t.boolean "service_cost_acceptance"
    t.boolean "informed_consent_acceptance"
    t.boolean "is_adult"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "signature"
  end

end
