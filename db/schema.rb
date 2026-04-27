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

ActiveRecord::Schema[8.1].define(version: 2026_04_25_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.integer "acompte_cents"
    t.datetime "created_at", null: false
    t.date "date"
    t.time "heure"
    t.string "mode_paiement"
    t.text "notes_cliente"
    t.bigint "prestation_id", null: false
    t.string "statut"
    t.string "stripe_payment_intent_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["prestation_id"], name: "index_bookings_on_prestation_id"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "fidelite_cards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "points"
    t.integer "recompenses_utilisees"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "visites"
    t.index ["user_id"], name: "index_fidelite_cards_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "contenu"
    t.datetime "created_at", null: false
    t.boolean "lu"
    t.string "titre"
    t.string "type_message"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "destinataire_email"
    t.string "destinataire_nom"
    t.integer "montant_cents"
    t.bigint "product_id", null: false
    t.string "statut"
    t.string "stripe_payment_intent_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["product_id"], name: "index_orders_on_product_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "prestations", force: :cascade do |t|
    t.string "categorie"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "disponible"
    t.integer "duree_minutes"
    t.string "nom"
    t.integer "prix_cents"
    t.datetime "updated_at", null: false
  end

  create_table "products", force: :cascade do |t|
    t.boolean "actif"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "nom"
    t.integer "prix_cents"
    t.string "type_produit"
    t.datetime "updated_at", null: false
  end

  create_table "soin_historiques", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.string "courbure"
    t.datetime "created_at", null: false
    t.string "epaisseur"
    t.string "longueur"
    t.text "note_syam"
    t.string "technique"
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_soin_historiques_on_booking_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.date "birth_date"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "bookings", "prestations"
  add_foreign_key "bookings", "users"
  add_foreign_key "fidelite_cards", "users"
  add_foreign_key "messages", "users"
  add_foreign_key "orders", "products"
  add_foreign_key "orders", "users"
  add_foreign_key "soin_historiques", "bookings"
end
