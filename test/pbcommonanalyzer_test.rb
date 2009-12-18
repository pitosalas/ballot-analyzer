=begin
  * Name: pbommonanalyzer2_test.rb
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
require 'ba/iadsl'
require 'ba/pbcommonanalyzer'


class PbCommonAnalyzerTest < Test::Unit::TestCase
  
  def assert_between(val1, val2, actual, message="")
    full_message = build_message(message, "<?> is expected to be between <?> and <?>.\n", actual, val1, val2)
    assert_block(full_message) { actual >= val1 && actual <= val2 }
  end
  
  context "Testing utility functions" do

    should "propertly test two values between assert" do
      assert_between(1, 5, 3)
    end

  end
  
  context "Analyzing 'test_ballot_1.tif" do
    setup do
      upstream = flexmock("upstream")
      upstream.should_receive(:ann_offset)
      @bi = PbCommonAnalyzer.new(upstream)
      fname = File.dirname(__FILE__) + "/fixtures/test_ballot_1.tif"
      @bi.open_ballot_image :test, fname, 200
      @bi.target_dpi = 200
#      @bi.diagnostics :intermediate_images
    end
    
    should "return a reasonable angle and origin for top timing marks" do
      marks = @bi.locate_marks :top, :test, 1/2.0
#      puts "top: angle #{angle}, origin #{offset}"
     assert_between 0.0, 0.3, marks.angle
     assert_between 0.0, 10, marks.firstmark.distance(BPoint.new(18, 6))
    end
        
    should "return a reasonable angle and origin for left timing marks" do
      marks = @bi.locate_marks :left, :test, 3/8.0
#       puts "left: angle #{angle}, origin #{origin}"
      assert_between 0.0, 0.3, marks.angle
      assert_between 0.0, 10, marks.firstmark.distance(BPoint.new(18, 6))
    end
    
    should "return a reasonable angle and origin for right  timing marks" do
      result = @bi.locate_marks :right, :test, 3/8.0
#      puts "right: angle #{angle}, origin #{offset}"
     assert_between 0.0, 0.3, result.angle
     assert_between 0.0, 10, result.firstmark.distance(BPoint.new(1662, 10))
    end
  end
  
  def test_analyze_ballot filename
    upstream = flexmock("upstream")
    upstream.should_receive(:ann_rect, :ann_offset)
    @bi = PbCommonAnalyzer.new(upstream)
    fname = File.dirname(__FILE__) + "/fixtures/" + filename
    @bi.open_ballot_image :test, fname, 200
    @bi.target_dpi = 200
#    @bi.diagnostics :intermediate_images
    res_top = @bi.locate_marks :top, :test, 3/4.0
    pp res_top

    res_left = @bi.locate_marks :left, :test, 3/8.0
    pp res_left

    res_right = @bi.locate_marks :right, :test, 3/8.0
    pp res_right
    
    [filename, res_top, res_left, res_right]
  end
  
  def close? goal, actual
    d = goal.distance(actual)
    0.0 <= d && d < 30.0
  end
  context "Analyzing a list of other ballots" do
    setup do
# Each entry: filename, TopLeft, BotLeft, TopRight, BotRight
      @speclist = [["test_ballot_1.tif", BPoint.new(18,6), BPoint.new(10, 2620), BPoint.new(1664, 10), BPoint.new(1654, 2624)]]
    end
    
    should "return a reasonable angles and origins for all of the ballot images" do
      @speclist.each do
        |testspec| # each speclist element is a test spec
        rarray = test_analyze_ballot testspec[0]
        result = close?(rarray[1].firstmark, testspec[1])
        result = result && close?(rarray[2].firstmark, testspec[1])
        result = result && close?(rarray[3].firstmark, testspec[3]) 
        if result
          assert true
        else
          puts rarray.inspect
          assert false, "failed processing #{filename} ballot. see console"
        end
      end
    end
  end
  
  context "geometry tests using point(0, 0) and point(10,10)" do
    setup do
      @p1 = BPoint.new(0,0)
      @p2 = BPoint.new(10,10)
    end
    
    should "find correct midpoint" do
      @line = BLine.new(@p1, @p2)
      assert_equal BPoint.new(5,5), @line.mid
    end
    
    should "find correct angle" do
      assert_equal 45.0, BPoint.angle(@p1, @p2)
    end
    
    should "rotate 0,0 correctly by 90 degrees" do
      assert_equal BPoint.new(0, 0), @p1.rotate(BPoint.deg_to_rad(90.0))
    end
    
    should "rotate 10, 10 correctly by 90 degrees" do
      assert_equal BPoint.new(-10.0, 10.0), @p2.rotate(BPoint.deg_to_rad(90.0))      
    end
    
    should "negage 10,10 correctly" do
      assert_equal BPoint.new(-10, -10), -@p2
    end
    
    should "offset 10, 10 correctly" do
      assert_equal BPoint.new(0,0), @p2.offset(-@p2)
    end
    
    should "find a bunch of correct angles" do
      [
        [100, 100, 100, 50, -90.0],
        [100, 100, 100, 150, 90.0], 
        [100, 100, 150, 100, 0.0],
        [100, 100, 150, 150, +45.0],
        [100, 100, 150, 50, -45.0],
        [100, 100, 50, 150, -45.0],
        [100, 100, 99, 99, 45.0]].each do
        |test|
          p1 = BPoint.new(test[0], test[1])
          p2 = BPoint.new(test[2], test[3])
          assert_equal test[4], BPoint.angle(p1, p2)
      end
    end
    
    should "find a bunch of others correctly too" do
      [[100, 100, 150, 100],
       [100, 100, 150, 50],
       [100, 100, 100, 50],
       [100, 100, 50, 50],
       [100, 100, 50, 100],
       [100, 100, 50, 150],
       [100, 100, 100, 150],
       [100, 100, 150, 150],
       [100, 100, 150, 100]].each do
         |test|
          p1 = BPoint.new(test[0], test[1])
          p2 = BPoint.new(test[2], test[3])
          angle = BPoint.angle(p1, p2)
#          puts "test: p1: #{p1}, p2: #{p2} -> #{angle}"   
       end
    end
  end
end
