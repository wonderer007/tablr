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

ActiveRecord::Schema[7.2].define(version: 2025_07_16_020042) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "complains", force: :cascade do |t|
    t.string "text"
    t.bigint "category_id", null: false
    t.bigint "review_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_complains_on_category_id"
    t.index ["review_id"], name: "index_complains_on_review_id"
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
    t.index ["category_id"], name: "index_keywords_on_category_id"
    t.index ["review_id"], name: "index_keywords_on_review_id"
  end

  create_table "places", force: :cascade do |t|
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
    t.index ["url"], name: "index_places_on_url", unique: true
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "place_id", null: false
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
    t.index ["created_at"], name: "index_reviews_on_created_at"
    t.index ["external_review_id"], name: "index_reviews_on_external_review_id", unique: true
    t.index ["food_rating"], name: "index_reviews_on_food_rating"
    t.index ["place_id", "processed"], name: "index_reviews_on_place_id_and_processed"
    t.index ["place_id", "published_at"], name: "index_reviews_on_place_id_and_published_at"
    t.index ["place_id", "stars"], name: "index_reviews_on_place_id_and_stars"
    t.index ["place_id"], name: "index_reviews_on_place_id"
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
    t.index ["category_id"], name: "index_suggestions_on_category_id"
    t.index ["review_id"], name: "index_suggestions_on_review_id"
  end

  add_foreign_key "complains", "categories"
  add_foreign_key "complains", "reviews"
  add_foreign_key "keywords", "categories"
  add_foreign_key "keywords", "reviews"
  add_foreign_key "reviews", "places"
  add_foreign_key "suggestions", "categories"
  add_foreign_key "suggestions", "reviews"
end
