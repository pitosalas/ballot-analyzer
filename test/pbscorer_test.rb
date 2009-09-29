=begin
  * Name: pbscorer_test.rb.rb
  * Description: Analyze voting ballots
  * Author: Pito Salas
  * Copyright: (c) R. Pito Salas and Associates, Inc.
  * Date: January 2009
  * License: GPL

  This file is part of Ballot-Analizer.

  Ballot-Analizer is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Ballot-Analizer is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Ballot-Analizer.  If not, see <http://www.gnu.org/licenses/>.

  require "ruby-debug"
  Debugger.settings[:autolist] = 1 # list nearby lines on stop
  Debugger.settings[:autoeval] = 1
  Debugger.start

=end
require File.dirname(__FILE__) + '/test_helper'
require 'ba/bascore'
require 'ba/ballotinfo'

class PBScorerTest < Test::Unit::TestCase

  Ballot_style_map2 = 
        { 1 => 
          { :name => '1311G-2',
            :coords => 
            [
              { :contest => :contst_amend_1,
                :choices => 
                { [9,  2] => 'yes',
                  [10, 2] => 'no'
                }
              },
              { :contest => :contst_amend_2,
                :choices => 
                { [20,  2] => 'yes',
                  [21, 2] => 'no'
                }
              },
              { :contest => :contst_amend_3,
                :choices => 
                { [32,  2] => 'yes',
                  [33, 2] => 'no'
                }
              },
              { :contest => :contst_amend_4,
                :choices => 
                { [47,  2] => 'yes',
                  [48, 2] => 'no'
                }
              },
              { :contest => :contst_amend_6,
                :choices => 
                { [13,  13] => 'yes',
                  [14, 13] => 'no'
                }
              },
              { :contest => :contst_amend_8,
                :choices => 
                { [23,  13] => 'yes',
                  [24, 13] => 'no'
                }
              },
              
            ]
          },
        2 =>
          { :name => '1311G-1',
            :coords =>
              [
                { :contest => :president,
                  :choices =>  
                    { [12, 2] => 'mccain',
                      [14, 2] => 'obama',
                      [16, 2] => 'riva',
                      [18, 2] => 'baldwin', 
                      [20, 2] => 'amondson',
                      [22, 2] => 'bar',
                      [24, 2] => 'stevens',
                      [26, 2] => 'harris',
                      [28, 2] => 'mckinney',
                      [30, 2] => 'keyes',
                      [32, 2] => 'nader',
                      [34, 2] => 'moore',
                      [36, 2] => 'jay',
                      [38, 2] => 'write-in'
                    }
                },
                { :contest => :secondcongres,
                  :choices => 
                    { [45, 2] => 'mulligan',
                      [47, 2] => 'boyd',
                      [49, 2] => 'write-in'
                    }
                },
                { :contest => :eightstatehouse,
                  :choices =>
                    { [13, 13] => 'williams',
                      [14, 13] => 'Maddox',
                      [15, 13] => 'write-in'}
                },
                { :contest => :justicesupreme_welles,
                  :choices =>
                    { [21, 13] => 'yes',
                      [22, 13] => 'no'
                    }
                },
                { :contest => :districtct_benton,
                  :choices => 
                    { [26, 13] => 'yes',
                      [27, 13] => 'no'
                    }
                 },
                { :contest => :districtct_davis,
                  :choices => 
                    { [31, 13] => 'yes',
                      [32, 13] => 'no'
                    }
                 },
                { :contest => :districtct_lewis,
                  :choices => 
                    { [36, 13] => 'yes',
                      [37, 13] => 'no'
                    }
                 }, 
                { :contest => :districtct_polston,
                  :choices => 
                    { [41, 13] => 'yes',
                      [42, 13] => 'no'
                    }
                 },
                { :contest => :districtct_nortwick,
                  :choices => 
                    { [11, 24] => 'yes',
                      [12, 24] => 'no'
                    }
                 },
                { :contest => :second_circuit_7,
                  :choices => 
                    { [16, 24] => 'raleigh',
                      [17, 24] => 'sheffield'
                    }
                 },
                { :contest => :county_judge_5,
                  :choices => 
                    { [21, 24] => 'richardson',
                      [22, 24] => 'desmond'
                    }
                 },
                { :contest => :county_comm_1,
                  :choices => 
                    { [28, 24] => 'akinyemi',
                      [29, 24] => 'dePuy'
                    }
                 },
               {  :contest => :city_comm_1,
                  :choices => 
                    { [35, 24] => 'mustian',
                      [36, 24] => 'write-in'
                    }
                 },
               { :contest => :water_dist_1_super,
                  :choices => 
                    { [42, 24] => 'acosta',
                      [43, 24] => 'mcglyn'
                    }
                 }                           
              ]
            }
          }
  
  context "A brand new PBScorer" do
    setup do
      @scorer = PBScorer.new
      @scorer.ballot_style_map = Ballot_style_map2
    end
    
    should "return an object of Class BallotInfo" do
      assert_equal BallotInfo, @scorer.results.class
    end
    
    context "using a tiny raw_data hash" do
      setup do
        @scorer.raw_data_hash = {}
      end
      
      should "still return object of Class BallotInfo" do
        assert_equal BallotInfo, @scorer.results.class
      end
      
      should "BallotInfo result should know a contest called 'president'" do
        assert  @scorer.results.contest? :president
      end
    end
    
    context "using the scores1.yaml fixture" do
      setup do 
        @scorer.load_raw_data(File.dirname(__FILE__) + "/fixtures/scores1.yml")
      end
      
      should "load fixture file" do
        assert @scorer.raw_data_hash != nil
      end
      
      should "contain the right number of raw results" do
        assert_equal 16, @scorer.total_count
      end
      
      should "contain right number of success analyses" do
        assert_equal 10, @scorer.success_count
      end
      
      should "contain right numbger of failed analyses" do
        assert_equal 6, @scorer.failed_count
      end
      
      should "be able to process the first record (which is a failure)" do
        assert !@scorer.process_record(0)
      end
      
      should "be able to process the third record (which is a success)" do
        assert @scorer.process_record(2)
      end
      
      context "working on record 2 of the input file" do
        setup do
          @scorer.process_record(2)
        end
        
        should "be precinct 1311G-1" do
          assert @scorer.results.precincts.include? "1311G-1"
        end
        
        should "be for 'stevens'" do
          assert_equal 1, @scorer.results.get_count("1311G-1", :president, "nader")
        end
      end
    end
  end
  
  context "PBScorer loaded with score2.yml" do
    setup do
      @scorer = PBScorer.new
      @scorer.load_raw_data(File.dirname(__FILE__) + "/fixtures/scores2.yml")
      @scorer.ballot_style_map = Ballot_style_map2
    end
    
    should "contain the right number of raw results" do
      assert_equal 50, @scorer.total_count
    end
    
    should "contain right number of success analyses" do
      assert_equal 44, @scorer.success_count
    end
    
    should "contain right numbger of failed analyses" do
      assert_equal 6, @scorer.failed_count
    end
    
    should "be able to process record 46 without exception" do
      assert_nothing_raised do
        @scorer.process_record 46
      end
    end
    
    should "process all records without exception" do
      assert_nothing_raised do
        @scorer.process_all_records
      end
    end
  end
  
  context "with score3.yml" do
    setup do 
      @scorer = PBScorer.new
      @scorer.load_raw_data(File.dirname(__FILE__) + "/fixtures/scores3.yml")
      @scorer.ballot_style_map = Ballot_style_map2
    end
        
    should "process all records without exception" do
      assert_nothing_raised do
        @scorer.process_all_records
      end
      puts @scorer.results.csv
    end
  end

end