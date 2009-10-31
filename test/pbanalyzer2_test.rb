=begin
  * Name: pbanalyzer2_test.rb
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
require 'ba/pbanalyzer2'

class PbAbalyzer2Test < Test::Unit::TestCase

  def assert_between(val1, val2, actual, message="")
    full_message = build_message(message, "<?> is expected to be between <?> and <?>.\n", actual, val1, val2)
    assert_block(full_message) { actual >= val1 && actual <= val2 }
  end

  context "A brand new BallotInfo without upstream set" do
    setup do
      @bi = PbAnalyzer2.new(nil)
    end
    
    should "say hello to world" do
      assert true
    end
    
    should "correctly convert between ballot coodiantes and inches" do
      @bi.target_dpi = 200
      assert_equal BPoint.new(0.5, 2.5), @bi.point_b2i(BPoint.new(2, 10)) 
    end
    
    should "processing an image should always return " do
      fname = File.dirname(__FILE__) + "/fixtures/test_ballot_1.tif"
      @result = {:filename => fname }
      upstream = flexmock("upstream")
      upstream.should_receive(:ann_offset)
      upstream.should_receive(:info).once    
      @bi.analyze_ballot_image fname, 200, @result, upstream
      assert @result.has_key? :raw_barcode
    end
  end
  
  context "Working on test_ballot_1" do
    setup do
      upstream = flexmock("upstream")
      upstream.should_receive(:ann_rect)
      upstream.should_receive(:ann_offset)
      upstream.should_receive(:ann_point)
      @bi = PbAnalyzer2.new(upstream)
      @bi.target_dpi = 200
      filename = File.dirname(__FILE__) + "/fixtures/test_ballot_1.tif"
      @up = upstream
      @bi.open_ballot_image :ballot, filename, @bi.target_dpi
    end
    
    should "Find a reasonable origin and angle" do
      @bi.locate_ballot
      assert_between 0.0, 0.4, @bi.ballot_angle
      assert_between 0.0, 20.0, @bi.ballot_origin.distance(BPoint.new(19, 19))
    end
    
    should "Find the voted ovals" do
      @bi.locate_ballot
      @bi.raw_marked_votes = []
      @bi.analyze_vote_ovals
      puts @bi.raw_marked_votes.inspect
    end

  end
  
  context "Working on test_ballot_2" do
    setup do
      upstream = flexmock("upstream")
      upstream.should_receive(:ann_offset, :ann_rect)
      assert upstream.ann_offset(1,2).nil?
      @bi = PbAnalyzer2.new(upstream)
      @bi.target_dpi = 200
      filename = File.dirname(__FILE__) + "/fixtures/test_ballot_2.tif"
      @bi.open_ballot_image :ballot, filename, @bi.target_dpi
    end
    
    should "Find a reasonable origin and angle" do
      @bi.locate_ballot
      assert_between 0.3, 0.7, @bi.ballot_angle
      assert_between 0.0, 20.0, @bi.ballot_origin.distance(BPoint.new(19, 90))
    end
    
    should "Find the voted ovals" do
      @bi.locate_ballot
      @bi.raw_marked_votes = []
      @bi.analyze_vote_ovals
      puts @bi.raw_marked_votes.inspect
    end    
  end
  
  context "test flexmock" do
    should "properly handle a should receive x" do
      upstream = flexmock(upstream)
      upstream.should_receive(:x)
      assert upstream.x.nil?
    end
    
    should "properly handle a should receive ann_offset" do
      upstream = flexmock(upstream)
      upstream.should_receive(:ann_offset)
      assert upstream.ann_offset(1,2).nil?
    end
  end
  
  context "Testing annotations on test_ballot_1" do
    setup do
      filename = File.dirname(__FILE__) + "/fixtures/test_ballot_1.tif"
      @upstream = ImageMagickUpstreamReporter.new(false, false, true)
      @upstream.ann_begin(filename, "test")
      @bi = PbAnalyzer2.new(@upstream)
      @bi.target_dpi = 200
      @bi.open_ballot_image :ballot, filename, @bi.target_dpi
    end
    
    should "generate an annotated image" do
      @bi.locate_ballot
      @bi.raw_marked_votes = []
      @bi.analyze_vote_ovals
      @upstream.ann_done("annotated")
    end
    
  end

end