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

ActiveRecord::Schema[8.1].define(version: 2026_07_19_051639) do
  create_table "boards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_boards_on_slug", unique: true
  end

  create_table "cards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", default: "", null: false
    t.integer "player_id", null: false
    t.integer "rarity", null: false
    t.integer "topic_id", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_cards_on_player_id"
    t.index ["topic_id", "player_id", "name"], name: "index_cards_on_topic_id_and_player_id_and_name", unique: true
    t.index ["topic_id"], name: "index_cards_on_topic_id"
  end

  create_table "offers", force: :cascade do |t|
    t.integer "card_id", null: false
    t.datetime "created_at", null: false
    t.integer "post_id", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_offers_on_card_id"
    t.index ["post_id", "card_id"], name: "index_offers_on_post_id_and_card_id", unique: true
    t.index ["post_id"], name: "index_offers_on_post_id"
  end

  create_table "players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_players_on_name", unique: true
    t.index ["team_id"], name: "index_players_on_team_id"
  end

  create_table "posts", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "nickname", null: false
    t.text "note"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_posts_on_status"
  end

  create_table "teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_teams_on_slug", unique: true
  end

  create_table "topics", force: :cascade do |t|
    t.integer "board_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["board_id", "slug"], name: "index_topics_on_board_id_and_slug", unique: true
    t.index ["board_id"], name: "index_topics_on_board_id"
  end

  create_table "wishes", force: :cascade do |t|
    t.integer "card_id", null: false
    t.datetime "created_at", null: false
    t.integer "post_id", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_wishes_on_card_id"
    t.index ["post_id", "card_id"], name: "index_wishes_on_post_id_and_card_id", unique: true
    t.index ["post_id"], name: "index_wishes_on_post_id"
  end

  add_foreign_key "cards", "players"
  add_foreign_key "cards", "topics"
  add_foreign_key "offers", "cards"
  add_foreign_key "offers", "posts"
  add_foreign_key "players", "teams"
  add_foreign_key "topics", "boards"
  add_foreign_key "wishes", "cards"
  add_foreign_key "wishes", "posts"
end
