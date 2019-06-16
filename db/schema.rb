# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_06_16_010704) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "fluid_inventory_thresholds", force: :cascade do |t|
    t.integer "threshold"
    t.bigint "product_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fluid_inventory_updates", force: :cascade do |t|
    t.integer "prior_wholesale_qty"
    t.integer "prior_retail_qty"
    t.integer "adjustment"
    t.integer "product_id"
    t.integer "new_wholesale_qty"
    t.integer "new_retail_qty"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "threshold"
  end

  create_table "inventory_updates", force: :cascade do |t|
    t.integer "product_id"
    t.integer "adjustment"
    t.integer "prior_qty"
    t.integer "vend_qty"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "new_qty"
  end

  create_table "products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "qbo_tokens", force: :cascade do |t|
    t.string "token"
    t.string "refresh_token"
    t.string "realm_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shopify_data", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "handle"
    t.string "product_type"
    t.text "tags"
    t.string "title"
    t.string "vendor"
    t.string "barcode"
    t.string "compare_at_price"
    t.string "fulfillment_service"
    t.integer "grams"
    t.bigint "inventory_item_id"
    t.string "inventory_management"
    t.string "inventory_policy"
    t.integer "inventory_quantity"
    t.integer "old_inventory_quantity"
    t.string "price"
    t.bigint "shopify_product_id"
    t.bigint "variant_id"
    t.string "requires_shipping"
    t.string "sku"
    t.string "variant_title"
    t.float "weight"
    t.string "weight_unit"
    t.datetime "variant_created_at"
    t.datetime "shopify_created_at"
    t.integer "product_id"
    t.integer "store"
  end

  create_table "shopify_inventories", force: :cascade do |t|
    t.bigint "location"
    t.integer "inventory"
    t.integer "shopify_datum_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shopify_refunds", force: :cascade do |t|
    t.float "cost", default: 0.0
    t.float "product_sales", default: 0.0
    t.float "sales_tax", default: 0.0
    t.float "discount", default: 0.0
    t.float "paypal_payments", default: 0.0
    t.float "total_payments", default: 0.0
    t.float "shopify_payments", default: 0.0
    t.float "shipping", default: 0.0
    t.float "gift_card_payments", default: 0.0
    t.json "location_costs", default: {}
    t.datetime "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shopify_sales_costs", force: :cascade do |t|
    t.float "cost", default: 0.0
    t.json "location_costs", default: {}
    t.datetime "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shopify_sales_receipts", force: :cascade do |t|
    t.float "product_sales", default: 0.0
    t.float "discount", default: 0.0
    t.float "shipping", default: 0.0
    t.float "sales_tax", default: 0.0
    t.float "gift_card_sales", default: 0.0
    t.float "shopify_payments", default: 0.0
    t.float "gift_card_payments", default: 0.0
    t.float "paypal_payments", default: 0.0
    t.datetime "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "remember_digest"
    t.boolean "admin", default: false
  end

  create_table "vend_data", force: :cascade do |t|
    t.boolean "active"
    t.string "brand"
    t.string "brand_id"
    t.text "categories"
    t.datetime "vend_created_at"
    t.datetime "vend_deleted_at"
    t.string "handle"
    t.boolean "has_inventory"
    t.boolean "has_variants"
    t.string "vend_id"
    t.boolean "is_active"
    t.string "name"
    t.string "product_type_id"
    t.string "sku"
    t.string "supplier"
    t.string "supplier_id"
    t.string "supply_price"
    t.text "tag_ids"
    t.text "vend_type"
    t.string "variant_count"
    t.string "variant_name"
    t.text "variant_options"
    t.string "variant_parent_id"
    t.integer "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "inventory"
  end

end
