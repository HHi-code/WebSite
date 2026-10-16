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

ActiveRecord::Schema[8.1].define(version: 2026_10_15_000005) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "catalogs", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "border_color", default: "#8B5CF6", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_catalogs_on_user_id"
  end

  create_table "elements", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.integer "rating", default: 0, null: false
    t.integer "catalog_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tier_list_id"
    t.index ["catalog_id"], name: "index_elements_on_catalog_id"
    t.index ["tier_list_id"], name: "index_elements_on_tier_list_id"
  end

  create_table "tier_list_elements", force: :cascade do |t|
    t.integer "tier_list_id", null: false
    t.integer "element_id", null: false
    t.string "rank", default: "unranked", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["element_id"], name: "index_tier_list_elements_on_element_id"
    t.index ["tier_list_id", "element_id"], name: "index_tier_list_elements_on_tier_list_id_and_element_id", unique: true
    t.index ["tier_list_id", "rank", "position"], name: "index_tier_list_elements_on_tier_list_id_and_rank_and_position"
    t.index ["tier_list_id"], name: "index_tier_list_elements_on_tier_list_id"
  end

  create_table "tier_lists", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_tier_lists_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "catalogs", "users"
  add_foreign_key "elements", "catalogs"
  add_foreign_key "elements", "tier_lists"
  add_foreign_key "tier_list_elements", "elements"
  add_foreign_key "tier_list_elements", "tier_lists"
  add_foreign_key "tier_lists", "users"
end
