=begin
  * Name: ballotinfo_test.rb
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
require 'ba/ballotinfo'

class BallotInfoTest < Test::Unit::TestCase
  context "A brand new BallotInfo" do
    setup do
      @bi = BallotInfo.new
    end
    
    should "have zero precincts" do
      assert @bi.precincts.length == 0
    end
    
    should "have zero contests" do
      assert @bi.contests.length == 0
    end
    
    context "with only 2 precincts defined" do
      setup do
        @bi.add_precinct(:bishop)
        @bi.add_precinct(:south)
      end
      
      should "know it has two precincts" do
        assert_equal 2, @bi.precincts.length
      end
      
      context "with two contests defined" do
        setup do
          @bi.add_contest(:president)
          @bi.add_contest(:mayor)
        end
        
        should "know it has two" do
          assert @bi.contests.length == 2
        end
        
        should "accept values for choices for contests" do
          assert_nothing_raised do
            @bi.add_contest_choice(:mayor, "john q public")
            @bi.add_contest_choice(:mayor, "jane q private")
          end
        end
              
        context "after counting a few choices" do
          setup do
            @bi.add_contest_choice(:mayor, "john q public")
            @bi.add_contest_choice(:mayor, "jane q private")
          end

          should "be able to add some results" do
            assert_nothing_raised do
              @bi.add_to_count(:bishop, :mayor, "john q public", 5)
            end
          end
          
          should "see the added results" do
           @bi.add_to_count(:bishop, :mayor, "john q public", 5)
           assert_equal 5, @bi.get_count(:bishop, :mayor, "john q public")
          end
       
          should "be able to add a series of results and then see the value" do
            @bi.add_to_count(:bishop, :mayor, "john q public", 3)
            @bi.add_to_count(:bishop, :mayor, "john q public", 5)
            @bi.add_to_count(:bishop, :mayor, "john q public", 9)
            @bi.add_to_count(:bishop, :mayor, "jane q private", 3)
            @bi.add_to_count(:bishop, :mayor, "jane q private", 5)
            @bi.add_to_count(:bishop, :mayor, "jane q private", 9)
            @bi.add_to_count(:bishop, :mayor, "jane with comma, yes>", 1)
            assert_equal 17, @bi.get_count(:bishop, :mayor, "jane q private")
            assert_equal 17, @bi.get_count(:bishop, :mayor, "john q public")   
            puts @bi.csv
          end
          
#          should "not allow an invalid name for a contest" do
#            assert_raises RuntimeError do
#              @bi.add_to_count(:bishop, :mayor, "faafoofay", 8)
#            end
#          end
      
          should "raise exception for invalid precinct" do
            assert_raises RuntimeError do
              @bi.get_count(:bad_precinct, :mayor, "john q public")
            end
          end
        end
      end
    end
  end
end