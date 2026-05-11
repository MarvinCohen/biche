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

ActiveRecord::Schema[8.1].define(version: 2026_05_01_124430) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.index ["date", "statut"], name: "index_bookings_on_date_and_statut"
    t.index ["date"], name: "index_bookings_on_date"
    t.index ["prestation_id"], name: "index_bookings_on_prestation_id"
    t.index ["statut"], name: "index_bookings_on_statut"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "carte_transactions", force: :cascade do |t|
    t.integer "booking_id"
    t.bigint "carte_cadeau_id", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.integer "montant_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["carte_cadeau_id"], name: "index_carte_transactions_on_carte_cadeau_id"
  end

  create_table "cartes_cadeaux", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.integer "montant_initial_cents", null: false
    t.bigint "order_id", null: false
    t.integer "solde_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_cartes_cadeaux_on_active"
    t.index ["code"], name: "index_cartes_cadeaux_on_code", unique: true
    t.index ["order_id"], name: "index_cartes_cadeaux_on_order_id"
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

  create_table "galerie_photos", force: :cascade do |t|
    t.string "categorie", null: false
    t.datetime "created_at", null: false
    t.string "legende", null: false
    t.string "legende_sub"
    t.integer "position", default: 0, null: false
    t.string "taille", default: "medium", null: false
    t.datetime "updated_at", null: false
    t.index ["categorie"], name: "index_galerie_photos_on_categorie"
    t.index ["position"], name: "index_galerie_photos_on_position"
  end

  create_table "indisponibilites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date_debut", null: false
    t.date "date_fin", null: false
    t.time "heure_debut", null: false
    t.time "heure_fin", null: false
    t.string "raison"
    t.datetime "updated_at", null: false
    t.index ["date_debut"], name: "index_indisponibilites_on_date_debut"
    t.index ["date_fin"], name: "index_indisponibilites_on_date_fin"
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
    t.index ["statut"], name: "index_orders_on_statut"
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

  create_table "videos", force: :cascade do |t|
    t.boolean "actif", default: true
    t.datetime "created_at", null: false
    t.integer "position", default: 0
    t.string "tag"
    t.string "titre", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["actif"], name: "index_videos_on_actif"
    t.index ["position"], name: "index_videos_on_position"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bookings", "prestations"
  add_foreign_key "bookings", "users"
  add_foreign_key "carte_transactions", "cartes_cadeaux"
  add_foreign_key "cartes_cadeaux", "orders"
  add_foreign_key "fidelite_cards", "users"
  add_foreign_key "messages", "users"
  add_foreign_key "orders", "products"
  add_foreign_key "orders", "users"
  add_foreign_key "soin_historiques", "bookings"
end
