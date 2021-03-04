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

ActiveRecord::Schema.define(version: 2021_03_04_063850) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "create_daily_inventory_transfers", force: :cascade do |t|
    t.datetime "date"
    t.integer "qbo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "daily_inventory_transfers", force: :cascade do |t|
    t.datetime "date"
    t.integer "qbo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "po_id"
    t.boolean "cancelled", default: false
  end

  create_table "daily_orders", force: :cascade do |t|
    t.string "outlet_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "vend_consignment_id"
    t.integer "daily_inventory_transfer_id"
    t.boolean "cancelled", default: false
    t.bigint "shopify_order_id"
    t.string "inventory_planner_id"
  end

  create_table "daily_shopify_pos_costs", force: :cascade do |t|
    t.datetime "date"
    t.bigint "qbo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "daily_shopify_pos_sales", force: :cascade do |t|
    t.datetime "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "daily_vend_consignments", force: :cascade do |t|
    t.datetime "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "qbo_id"
  end

  create_table "daily_vend_costs", force: :cascade do |t|
    t.datetime "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "qbo_id"
  end

  create_table "daily_vend_sales", force: :cascade do |t|
    t.datetime "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "inventory_updates", force: :cascade do |t|
    t.integer "product_id"
    t.integer "adjustment"
    t.integer "prior_qty"
    t.integer "vend_qty"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "new_qty"
    t.bigint "location", default: 49481991
  end

  create_table "orders", force: :cascade do |t|
    t.integer "quantity"
    t.integer "product_id"
    t.integer "daily_order_id"
    t.integer "threshold"
    t.integer "vend_qty"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "cost"
    t.integer "sent_orders", default: 0
    t.boolean "cancelled", default: false
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
    t.string "option1"
    t.string "option2"
    t.string "option3"
    t.float "cost", default: 0.0
  end

  create_table "shopify_deletions", force: :cascade do |t|
    t.integer "product_id"
    t.bigint "deleted_variant_id"
    t.bigint "new_variant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "deleted_shopify_product_id"
    t.bigint "new_shopify_product_id"
  end

  create_table "shopify_duplicates", force: :cascade do |t|
    t.integer "product_id"
    t.bigint "original_variant_id"
    t.bigint "duplicate_variant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "original_shopify_product_id"
    t.bigint "duplicate_shopify_product_id"
  end

  create_table "shopify_inventories", force: :cascade do |t|
    t.bigint "location"
    t.integer "inventory"
    t.integer "shopify_datum_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shopify_pos_location_sales_taxes", force: :cascade do |t|
    t.float "amount", default: 0.0
    t.float "sales_tax", default: 0.0
    t.float "shipping", default: 0.0
    t.bigint "location"
    t.integer "shopify_pos_sales_tax_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shopify_pos_refunds", force: :cascade do |t|
    t.float "arbitrary_discount", default: 0.0
    t.float "cost", default: 0.0
    t.float "discount", default: 0.0
    t.float "gift_card_payments", default: 0.0
    t.float "paypal_payments", default: 0.0
    t.float "product_sales", default: 0.0
    t.float "refunded_shipping", default: 0.0
    t.float "sales_tax", default: 0.0
    t.float "shipping", default: 0.0
    t.float "shopify_payments", default: 0.0
    t.float "total_payments", default: 0.0
    t.float "cash_payments", default: 0.0
    t.integer "shopify_refund_id"
    t.bigint "location_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shopify_pos_sales_cost_orders", force: :cascade do |t|
    t.datetime "sale_at"
    t.float "cost", default: 0.0
    t.bigint "location"
    t.string "name"
    t.bigint "order_id"
    t.integer "daily_shopify_pos_cost_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shopify_pos_sales_costs", force: :cascade do |t|
    t.float "cost", default: 0.0
    t.bigint "location"
    t.integer "daily_shopify_pos_cost_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shopify_pos_sales_receipt_sales", force: :cascade do |t|
    t.float "gift_card_sales", default: 0.0
    t.float "gift_card_payments", default: 0.0
    t.float "credit_payments", default: 0.0
    t.float "cash_payments", default: 0.0
    t.float "product_sales", default: 0.0
    t.float "discount", default: 0.0
    t.float "discount_sales", default: 0.0
    t.float "sales_tax", default: 0.0
    t.float "shipping", default: 0.0
    t.bigint "location"
    t.integer "daily_shopify_pos_sale_id"
    t.string "name"
    t.datetime "sale_at"
    t.bigint "order_id"
    t.float "rentals", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shopify_pos_sales_receipts", force: :cascade do |t|
    t.float "gift_card_sales", default: 0.0
    t.float "gift_card_payments", default: 0.0
    t.float "credit_payments", default: 0.0
    t.float "cash_payments", default: 0.0
    t.float "product_sales", default: 0.0
    t.float "discount", default: 0.0
    t.float "discount_sales", default: 0.0
    t.float "sales_tax", default: 0.0
    t.float "shipping", default: 0.0
    t.bigint "location"
    t.integer "daily_shopify_pos_sale_id"
    t.bigint "qbo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shopify_pos_sales_taxes", force: :cascade do |t|
    t.integer "daily_shopify_pos_sale_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shopify_refund_orders", force: :cascade do |t|
    t.bigint "order_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.integer "shopify_refund_id"
    t.float "cost", default: 0.0
    t.float "discount", default: 0.0
    t.float "gift_card_payments", default: 0.0
    t.float "shopify_payments", default: 0.0
    t.float "paypal_payments", default: 0.0
    t.json "location_costs"
    t.float "product_sales", default: 0.0
    t.float "refunded_shipping", default: 0.0
    t.float "sales_tax", default: 0.0
    t.float "shipping", default: 0.0
    t.float "total_payments", default: 0.0
    t.datetime "updated_at", null: false
    t.float "arbitrary_discount", default: 0.0
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
    t.float "refunded_shipping", default: 0.0
    t.float "arbitrary_discount", default: 0.0
    t.bigint "qbo_id"
  end

  create_table "shopify_sales_cost_orders", force: :cascade do |t|
    t.bigint "order_id"
    t.string "name"
    t.datetime "closed_at"
    t.float "cost", default: 0.0
    t.json "location_costs"
    t.integer "shopify_sales_cost_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "store", default: 0
  end

  create_table "shopify_sales_costs", force: :cascade do |t|
    t.float "cost", default: 0.0
    t.json "location_costs", default: {}
    t.datetime "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "store", default: 0
    t.bigint "qbo_id"
  end

  create_table "shopify_sales_receipt_orders", force: :cascade do |t|
    t.bigint "order_id"
    t.string "name"
    t.datetime "closed_at"
    t.float "sales_tax", default: 0.0
    t.float "discount", default: 0.0
    t.float "product_sales", default: 0.0
    t.float "shipping", default: 0.0
    t.float "shopify_payments", default: 0.0
    t.float "gift_card_payments", default: 0.0
    t.float "paypal_payments", default: 0.0
    t.float "gift_card_sales", default: 0.0
    t.integer "shopify_sales_receipt_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "store", default: 0
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
    t.integer "store", default: 0
    t.bigint "qbo_id"
  end

  create_table "sos_tokens", force: :cascade do |t|
    t.text "access_token"
    t.text "refresh_token"
    t.integer "expires_in"
    t.string "token_type"
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

  create_table "vend_consignment_location_costs", force: :cascade do |t|
    t.integer "daily_vend_consignment_id"
    t.float "cost", default: 0.0
    t.string "outlet_id"
    t.integer "role", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "vend_consignments", force: :cascade do |t|
    t.integer "daily_vend_consignment_id"
    t.float "cost", default: 0.0
    t.string "receiving_id"
    t.string "supplying_id"
    t.string "vend_consignment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "received_at"
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
  end

  create_table "vend_inventories", force: :cascade do |t|
    t.integer "inventory"
    t.string "outlet_id"
    t.integer "vend_datum_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "vend_location_sales_taxes", force: :cascade do |t|
    t.integer "vend_sales_tax_id"
    t.float "sales_tax", default: 0.0
    t.float "shipping", default: 0.0
    t.float "amount", default: 0.0
    t.string "outlet_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "vend_sales_cost_sales", force: :cascade do |t|
    t.float "cost", default: 0.0
    t.string "outlet_id"
    t.string "sale_id"
    t.integer "daily_vend_cost_id"
    t.datetime "sale_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "receipt_number"
  end

  create_table "vend_sales_costs", force: :cascade do |t|
    t.string "outlet_id"
    t.integer "daily_vend_cost_id"
    t.float "cost", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "vend_sales_receipt_sales", force: :cascade do |t|
    t.float "gift_card_sales", default: 0.0
    t.float "gift_card_payments", default: 0.0
    t.float "credit_payments", default: 0.0
    t.float "cash_or_check_payments", default: 0.0
    t.float "product_sales", default: 0.0
    t.float "discount", default: 0.0
    t.float "discount_sales", default: 0.0
    t.float "sales_tax", default: 0.0
    t.float "shipping", default: 0.0
    t.integer "daily_vend_sale_id"
    t.string "outlet_id"
    t.string "sale_id"
    t.datetime "sale_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "receipt_number"
    t.float "rentals", default: 0.0
  end

  create_table "vend_sales_receipts", force: :cascade do |t|
    t.float "gift_card_sales", default: 0.0
    t.float "gift_card_payments", default: 0.0
    t.float "credit_payments", default: 0.0
    t.float "cash_or_check_payments", default: 0.0
    t.float "product_sales", default: 0.0
    t.float "discount", default: 0.0
    t.float "sales_tax", default: 0.0
    t.string "outlet_id"
    t.float "shipping", default: 0.0
    t.integer "daily_vend_sale_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "discount_sales", default: 0.0
    t.bigint "qbo_id"
  end

  create_table "vend_sales_taxes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "daily_vend_sale_id"
  end

  create_table "wholesale_order_items", force: :cascade do |t|
    t.string "department"
    t.string "item_name"
    t.float "unit_price", default: 0.0
    t.bigint "sos_item_id"
    t.integer "quantity_ordered", default: 0
    t.integer "wholesale_order_id"
  end

  create_table "wholesale_orders", force: :cascade do |t|
    t.integer "sos_id"
    t.string "ref_number"
    t.string "customer"
    t.string "customer_po"
    t.bigint "sos_customer_id"
    t.string "location"
    t.datetime "start_ship"
    t.datetime "cancel_date"
    t.float "sos_total"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
