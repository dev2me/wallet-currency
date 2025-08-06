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

ActiveRecord::Schema[8.0].define(version: 2025_08_06_181054) do
  create_table "users", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "wallet_transactions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "transaction_type"
    t.string "from_currency"
    t.string "to_currency"
    t.decimal "amount"
    t.decimal "result_amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "currency"
    t.index ["user_id"], name: "index_wallet_transactions_on_user_id"
  end

  create_table "wallets", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "currency"
    t.decimal "balance", precision: 15, scale: 4
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_wallets_on_user_id"
  end

  add_foreign_key "wallet_transactions", "users"
  add_foreign_key "wallets", "users"
end
