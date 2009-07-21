# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090715231044) do

  create_table "candidates", :force => true do |t|
    t.string   "display_name"
    t.integer  "party_id"
    t.integer  "contest_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "contests", :force => true do |t|
    t.string   "display_name"
    t.integer  "open_seat_count"
    t.integer  "voting_method_id"
    t.integer  "district_id"
    t.integer  "election_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "district_sets", :force => true do |t|
    t.string   "internal_name"
    t.integer  "main_district"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "district_sets_districts", :id => false, :force => true do |t|
    t.integer "district_set_id"
    t.integer "district_id"
  end

  create_table "district_types", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  
  
  
# Outside schema.rb, other ActiveRecord db statements are:

  class Candidate < ActiveRecord::Base
   belongs_to :contest
  end

  class Contest < ActiveRecord::Base
   belongs_to  :district
   belongs_to :election
   has_many :candidates
  end

  class District < ActiveRecord::Base
   has_and_belongs_to_many :district_sets
   has_and_belongs_to_many :precincts
   has_many :contests
  end

  class DistrictSet < ActiveRecord::Base
   has_and_belongs_to_many :districts
  end

  class Election < ActiveRecord::Base
     has_many :contests
  end

  class Precinct < ActiveRecord::Base
   has_and_belongs_to_many :districts
  end

  create_table "districts", :force => true do |t|
    t.integer  "district_type_id"
    t.string   "internal_name"
    t.string   "display_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "districts_precincts", :id => false, :force => true do |t|
    t.integer "precinct_id"
    t.integer "district_id"
  end

  create_table "elections", :force => true do |t|
    t.string   "display_name"
    t.string   "internal_name"
    t.integer  "district_set_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "parties", :force => true do |t|
    t.string   "display_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "precincts", :force => true do |t|
    t.string   "internal_name"
    t.string   "display_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "voting_methods", :force => true do |t|
    t.string   "display_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
