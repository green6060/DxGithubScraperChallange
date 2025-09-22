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

ActiveRecord::Schema[7.2].define(version: 2025_09_22_013221) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "pull_requests", force: :cascade do |t|
    t.bigint "repository_id", null: false
    t.string "github_id", null: false
    t.integer "number", null: false
    t.string "title", null: false
    t.bigint "author_id", null: false
    t.datetime "closed_at"
    t.datetime "merged_at"
    t.integer "additions", default: 0
    t.integer "deletions", default: 0
    t.integer "changed_files", default: 0
    t.integer "commit_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_pull_requests_on_author_id"
    t.index ["github_id"], name: "index_pull_requests_on_github_id", unique: true
    t.index ["repository_id"], name: "index_pull_requests_on_repository_id"
  end

  create_table "repositories", force: :cascade do |t|
    t.string "github_id", null: false
    t.string "name", null: false
    t.string "url", null: false
    t.boolean "is_private", default: false
    t.boolean "is_archived", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["github_id"], name: "index_repositories_on_github_id", unique: true
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "pull_request_id", null: false
    t.string "github_id", null: false
    t.bigint "reviewer_id", null: false
    t.string "state", null: false
    t.datetime "submitted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["github_id"], name: "index_reviews_on_github_id", unique: true
    t.index ["pull_request_id"], name: "index_reviews_on_pull_request_id"
    t.index ["reviewer_id"], name: "index_reviews_on_reviewer_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "github_id", null: false
    t.string "login", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "email"
    t.text "bio"
    t.string "company"
    t.string "location"
    t.string "blog"
    t.string "twitter_username"
    t.integer "public_repos"
    t.integer "public_gists"
    t.integer "followers"
    t.integer "following"
    t.datetime "github_created_at"
    t.datetime "github_updated_at"
    t.index ["github_id"], name: "index_users_on_github_id", unique: true
  end

  add_foreign_key "pull_requests", "repositories"
  add_foreign_key "pull_requests", "users", column: "author_id"
  add_foreign_key "reviews", "pull_requests"
  add_foreign_key "reviews", "users", column: "reviewer_id"
end
