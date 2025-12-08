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

ActiveRecord::Schema[8.1].define(version: 2025_12_07_203813) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_keys", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key_hash", null: false
    t.string "project", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["key_hash"], name: "index_api_keys_on_key_hash", unique: true
    t.index ["user_id", "project"], name: "index_api_keys_on_user_id_and_project"
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "api_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "api_key_id", null: false
    t.datetime "created_at", null: false
    t.string "endpoint", null: false
    t.jsonb "fingerprint", default: {}, null: false
    t.inet "ip_address", null: false
    t.jsonb "request_body", default: {}, null: false
    t.integer "response_status", null: false
    t.datetime "updated_at", null: false
    t.index ["api_key_id"], name: "index_api_requests_on_api_key_id"
    t.index ["created_at"], name: "index_api_requests_on_created_at"
    t.index ["ip_address"], name: "index_api_requests_on_ip_address"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "hca_id", null: false
    t.datetime "updated_at", null: false
    t.index ["hca_id"], name: "index_users_on_hca_id", unique: true
  end

  add_foreign_key "api_keys", "users"
  add_foreign_key "api_requests", "api_keys"
end
