# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160221112305) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assocs", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.date     "birthday"
    t.string   "city"
    t.decimal  "latitude"
    t.decimal  "longitude"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "av_links", force: :cascade do |t|
    t.integer  "assoc_id"
    t.integer  "volunteer_id"
    t.string   "rights"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "level"
  end

  create_table "event_volunteers", force: :cascade do |t|
    t.integer  "event_id"
    t.integer  "volunteer_id"
    t.string   "rights"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "level"
  end

  create_table "events", force: :cascade do |t|
    t.string   "title"
    t.string   "description"
    t.string   "place"
    t.datetime "begin"
    t.datetime "end"
    t.integer  "assoc_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "notification_add_friends", force: :cascade do |t|
    t.integer  "sender_volunteer_id"
    t.integer  "receiver_volunteer_id"
    t.boolean  "acceptance"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "notification_invite_guests", force: :cascade do |t|
    t.integer  "volunteer_id"
    t.integer  "event_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "notification_invite_members", force: :cascade do |t|
    t.integer  "sender_assoc_id"
    t.integer  "receiver_volunteer_id"
    t.boolean  "acceptance"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "notification_join_assocs", force: :cascade do |t|
    t.integer  "sender_volunteer_id"
    t.integer  "receiver_assoc_id"
    t.boolean  "acceptance"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  create_table "notification_join_events", force: :cascade do |t|
    t.integer  "volunteer_id"
    t.integer  "event_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "v_friends", force: :cascade do |t|
    t.integer  "current_volunteer_id"
    t.integer  "friend_volunteer_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "volunteers", force: :cascade do |t|
    t.string   "mail"
    t.string   "token"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "password"
    t.string   "firstname"
    t.string   "lastname"
    t.date     "birthday"
    t.string   "gender"
    t.string   "city"
    t.decimal  "latitude"
    t.decimal  "longitude"
    t.boolean  "allowgps",            default: false
    t.boolean  "allow_notifications"
  end

end
