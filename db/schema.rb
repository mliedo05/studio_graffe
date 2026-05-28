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

ActiveRecord::Schema[8.1].define(version: 2026_04_24_172036) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.string "namespace"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "appointments", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.boolean "commission_paid", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "ends_at", null: false
    t.text "notes"
    t.string "number", null: false
    t.integer "price_cents", default: 0, null: false
    t.bigint "service_id", null: false
    t.datetime "starts_at", null: false
    t.string "status", default: "pending", null: false
    t.bigint "stylist_id", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_appointments_on_client_id"
    t.index ["number"], name: "index_appointments_on_number", unique: true
    t.index ["service_id"], name: "index_appointments_on_service_id"
    t.index ["starts_at"], name: "index_appointments_on_starts_at"
    t.index ["status"], name: "index_appointments_on_status"
    t.index ["stylist_id"], name: "index_appointments_on_stylist_id"
  end

  create_table "commissions", force: :cascade do |t|
    t.integer "amount_cents", default: 0, null: false
    t.bigint "appointment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "paid_at"
    t.integer "percentage", null: false
    t.string "status", default: "pending", null: false
    t.bigint "stylist_id", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_commissions_on_appointment_id"
    t.index ["status"], name: "index_commissions_on_status"
    t.index ["stylist_id"], name: "index_commissions_on_stylist_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "total_price_cents", default: 0, null: false
    t.integer "unit_price_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "number", null: false
    t.string "payment_method"
    t.string "payment_status", default: "pending", null: false
    t.string "payment_token"
    t.string "status", default: "cart", null: false
    t.integer "subtotal_cents", default: 0, null: false
    t.integer "total_cents", default: 0, null: false
    t.string "transaction_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["number"], name: "index_orders_on_number", unique: true
    t.index ["payment_status"], name: "index_orders_on_payment_status"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "product_categories", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_product_categories_on_slug", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "brand", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "featured", default: false, null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "price_cents", default: 0, null: false
    t.bigint "product_category_id", null: false
    t.string "sku"
    t.string "slug", null: false
    t.integer "stock_quantity", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_products_on_active"
    t.index ["featured"], name: "index_products_on_featured"
    t.index ["product_category_id"], name: "index_products_on_product_category_id"
    t.index ["slug"], name: "index_products_on_slug", unique: true
  end

  create_table "services", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "duration_minutes", default: 60, null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "price_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_services_on_active"
    t.index ["category"], name: "index_services_on_category"
  end

  create_table "stylist_blocked_times", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ends_at", null: false
    t.string "reason"
    t.datetime "starts_at", null: false
    t.bigint "stylist_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stylist_id"], name: "index_stylist_blocked_times_on_stylist_id"
  end

  create_table "stylist_profiles", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "bio"
    t.integer "commission_percentage", default: 35, null: false
    t.datetime "created_at", null: false
    t.string "instagram_handle"
    t.string "specialties", default: [], array: true
    t.bigint "stylist_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stylist_id"], name: "index_stylist_profiles_on_stylist_id"
  end

  create_table "stylist_schedules", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.integer "day_of_week", null: false
    t.time "end_time", null: false
    t.time "start_time", null: false
    t.bigint "stylist_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stylist_id", "day_of_week"], name: "index_stylist_schedules_on_stylist_id_and_day_of_week", unique: true
    t.index ["stylist_id"], name: "index_stylist_schedules_on_stylist_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "client", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "appointments", "services"
  add_foreign_key "appointments", "users", column: "client_id"
  add_foreign_key "appointments", "users", column: "stylist_id"
  add_foreign_key "commissions", "appointments"
  add_foreign_key "commissions", "users", column: "stylist_id"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "users"
  add_foreign_key "products", "product_categories"
  add_foreign_key "stylist_blocked_times", "users", column: "stylist_id"
  add_foreign_key "stylist_profiles", "users", column: "stylist_id"
  add_foreign_key "stylist_schedules", "users", column: "stylist_id"
end
