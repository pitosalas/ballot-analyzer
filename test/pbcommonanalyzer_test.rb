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
      @bi = PbCommonAnalyzer.new(upstream)
      fname = File.dirname(__FILE__) + "/fixtures/test_ballot_1.tif"
      @bi.open_ballot_image :test, fname, 200
      @bi.target_dpi = 200
      @bi.diagnostics :intermediate_images
    end
    
    should "return a reasonable angle and origin for top timing marks" do
      origin, angle = @bi.locate_marks :top, :test, 1/2.0
#      puts "top: angle #{angle}, origin #{offset}"
     assert_between 0.0, 0.3, angle
     assert_between 0.0, 10, origin.distance(Point.new(18, 6))
    end
        
    should "return a reasonable angle and origin for left timing marks" do
      origin, angle = @bi.locate_marks :left, :test, 3/8.0
#       puts "left: angle #{angle}, origin #{origin}"
      assert_between 0.0, 0.3, angle
      assert_between 0.0, 10, origin.distance(Point.new(18, 6))
    end
    
    should "return a reasonable angle and origin for right  timing marks" do
      origin, angle = @bi.locate_marks :right, :test, 3/8.0
#      puts "right: angle #{angle}, origin #{offset}"
     assert_between 0.0, 0.3, angle
     assert_between 0.0, 10, origin.distance(Point.new(18, 6))
    end
  end
  
  def analyze_ballot filename
    upstream = flexmock("upstream")
    @bi = PbCommonAnalyzer.new(upstream)
    fname = File.dirname(__FILE__) + "/fixtures/" + filename
    @bi.open_ballot_image :test, fname, 200
    @bi.target_dpi = 200
    @bi.diagnostics :intermediate_images
    origin_top, angle_top = @bi.locate_marks :top, :test, 3/4.0
    puts "top: angle #{angle_top}, origin #{origin_top}"

    origin_left, angle_left = @bi.locate_marks :left, :test, 3/8.0
    puts "left: angle #{angle_left}, origin #{origin_left}"

    origin_right, angle_right = @bi.locate_marks :right, :test, 3/8.0
    puts "right: angle #{angle_right}, origin #{origin_right}"
    [filename, origin_top, angle_top, origin_left, angle_left, origin_right, angle_right]
  end
  
  def reasonable_result origin, angle, act_x, act_y, act_angle
    o_distance = origin.distance(Point.new(act_x, act_y))
    o_distance >= 0.0 && o_distance < 10.0 && angle > 0.0 && angle < act_angle
  end

  
  context "Analyzing a list of other ballots" do
    setup do
      @speclist = [["test_ballot_1.tif", 18, 6, 1.0], ["test_ballot_2.tif", 20, 90, 1.0]]
    end
    
    should "return a reasonable angles and origins for all of the ballot images" do
      @speclist.each do
        |testspec| # each speclist element is a test spec: filename, x, y of 'actual origin', and angle of 'actual rotation
        ra = analyze_ballot testspec[0]
        result = reasonable_result(ra[1], ra[2], testspec[1], testspec[2], testspec[3]) && 
                 reasonable_result(ra[3], ra[4], testspec[1], testspec[2], testspec[3]) && 
                 reasonable_result(ra[5], ra[6], testspec[1], testspec[2], testspec[3])
        if result
          assert true
        else
          puts ra.inspect
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
      assert_equal Point.new(0, 0), @p1.rotate(BPoint.deg_to_rad(90.0))
    end
    
    should "rotate 10, 10 correctly by 90 degrees" do
      assert_equal Point.new(-10.0, 10.0), @p2.rotate(BPoint.deg_to_rad(90.0))      
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
