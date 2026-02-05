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

ActiveRecord::Schema[7.2].define(version: 2026_02_06_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "businesses", force: :cascade do |t|
    t.string "name"
    t.string "place_actor_run_id"
    t.string "review_actor_run_id"
    t.datetime "review_synced_at"
    t.datetime "place_synced_at"
    t.integer "status"
    t.string "url"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "rating"
    t.boolean "first_inference_completed", default: false
    t.boolean "test", default: false
    t.string "business_type", default: "google_place", null: false
    t.boolean "onboarding_completed", default: false
    t.string "plan", default: "free", null: false
    t.boolean "payment_approved", default: false
    t.integer "type", default: 0
    t.index ["business_type"], name: "index_businesses_on_business_type"
    t.index ["plan"], name: "index_businesses_on_plan"
    t.index ["type"], name: "index_businesses_on_type"
    t.index ["url", "test"], name: "index_businesses_on_url_and_test", unique: true
    t.index ["url"], name: "index_businesses_on_url"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "business_id", default: 1, null: false
    t.index ["business_id", "name"], name: "index_categories_on_business_id_and_name", unique: true
    t.index ["business_id"], name: "index_categories_on_business_id"
  end

  create_table "complains", force: :cascade do |t|
    t.string "text"
    t.bigint "category_id", null: false
    t.bigint "review_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "business_id", default: 1, null: false
    t.integer "severity"
    t.index ["business_id"], name: "index_complains_on_business_id"
    t.index ["category_id"], name: "index_complains_on_category_id"
    t.index ["review_id"], name: "index_complains_on_review_id"
  end

  create_table "demo_requests", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "restaurant_name"
    t.string "google_map_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "inference_requests", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.jsonb "response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "input_token_count"
    t.integer "output_token_count"
    t.index ["business_id"], name: "index_inference_requests_on_business_id"
  end

  create_table "keywords", force: :cascade do |t|
    t.bigint "review_id", null: false
    t.string "name"
    t.integer "sentiment"
    t.float "sentiment_score"
    t.bigint "category_id", null: false
    t.boolean "is_dish", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "business_id", default: 1, null: false
    t.index ["category_id"], name: "index_keywords_on_category_id"
    t.index ["review_id"], name: "index_keywords_on_review_id"
  end

  create_table "marketing_companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "linkedin_url"
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "country"
    t.string "phone"
    t.string "google_map_url"
    t.bigint "business_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_marketing_companies_on_business_id"
  end

  create_table "marketing_contacts", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "email_sent_at"
    t.float "email_confidence"
    t.string "secondary_email"
    t.datetime "primary_email_last_verified_at"
    t.integer "no_of_employees"
    t.string "industry"
    t.string "linkedin_url"
    t.string "website"
    t.string "twitter_url"
    t.string "city"
    t.string "country"
    t.float "annual_revenue"
    t.boolean "unsubscribed", default: false
    t.bigint "company_id"
    t.string "company_name", limit: 255
    t.string "unsubscribe_token"
    t.string "unsubscribe_reason"
    t.jsonb "never_bounce_response"
    t.string "email_status"
    t.index ["company_id"], name: "index_marketing_contacts_on_company_id"
    t.index ["email"], name: "index_marketing_contacts_on_email", unique: true
    t.index ["email_status"], name: "index_marketing_contacts_on_email_status"
    t.index ["secondary_email"], name: "index_marketing_contacts_on_secondary_email"
    t.index ["unsubscribe_token"], name: "index_marketing_contacts_on_unsubscribe_token", unique: true
  end

  create_table "marketing_emails", force: :cascade do |t|
    t.integer "marketing_contact_id"
    t.integer "business_id"
    t.string "subject"
    t.text "body"
    t.datetime "sent_at"
    t.string "status"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "ai_generated_intro"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "text", null: false
    t.boolean "read", default: false
    t.string "notification_type", null: false
    t.bigint "business_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_notifications_on_business_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.jsonb "review_context"
    t.string "review_url"
    t.string "external_review_id"
    t.string "text"
    t.integer "stars"
    t.integer "likes_count"
    t.integer "food_rating"
    t.integer "service_rating"
    t.integer "atmosphere_rating"
    t.datetime "published_at"
    t.jsonb "data"
    t.boolean "processed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "image_url"
    t.integer "sentiment"
    t.index ["atmosphere_rating"], name: "index_reviews_on_atmosphere_rating"
    t.index ["business_id", "external_review_id"], name: "index_reviews_on_business_id_and_external_review_id", unique: true
    t.index ["business_id", "processed"], name: "index_reviews_on_business_id_and_processed"
    t.index ["business_id", "published_at"], name: "index_reviews_on_business_id_and_published_at"
    t.index ["business_id", "stars"], name: "index_reviews_on_business_id_and_stars"
    t.index ["business_id"], name: "index_reviews_on_business_id"
    t.index ["created_at"], name: "index_reviews_on_created_at"
    t.index ["food_rating"], name: "index_reviews_on_food_rating"
    t.index ["processed"], name: "index_reviews_on_processed"
    t.index ["published_at"], name: "index_reviews_on_published_at"
    t.index ["service_rating"], name: "index_reviews_on_service_rating"
    t.index ["stars"], name: "index_reviews_on_stars"
    t.index ["text"], name: "index_reviews_on_text", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "suggestions", force: :cascade do |t|
    t.string "text"
    t.bigint "category_id", null: false
    t.bigint "review_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "business_id", default: 1, null: false
    t.integer "severity"
    t.index ["business_id"], name: "index_suggestions_on_business_id"
    t.index ["category_id"], name: "index_suggestions_on_category_id"
    t.index ["review_id"], name: "index_suggestions_on_review_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.bigint "business_id"
    t.string "first_name"
    t.string "last_name"
    t.string "phone_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "email_notification_period", default: 2
    t.integer "email_notification_time", default: 0
    t.string "provider"
    t.string "uid"
    t.string "avatar_url"
    t.boolean "email_notification", default: true, null: false
    t.index ["business_id"], name: "index_users_on_business_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "categories", "businesses"
  add_foreign_key "complains", "businesses"
  add_foreign_key "complains", "categories"
  add_foreign_key "complains", "reviews"
  add_foreign_key "inference_requests", "businesses"
  add_foreign_key "keywords", "businesses"
  add_foreign_key "keywords", "categories"
  add_foreign_key "keywords", "reviews"
  add_foreign_key "marketing_companies", "businesses"
  add_foreign_key "marketing_contacts", "marketing_companies", column: "company_id"
  add_foreign_key "notifications", "businesses"
  add_foreign_key "reviews", "businesses"
  add_foreign_key "suggestions", "businesses"
  add_foreign_key "suggestions", "categories"
  add_foreign_key "suggestions", "reviews"
  add_foreign_key "users", "businesses"
end
