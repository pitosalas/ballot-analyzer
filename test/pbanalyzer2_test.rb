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
require 'ba/bautils'

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
    
    should "correctly convert between ballot coodiantes and ballot fractional coord" do
      @bi.target_dpi = 200
      assert_equal BPoint.new(1.0, 1.0), @bi.point_b2f(BPoint.new(33, 52)) 
    end
    
    should "processing an image should always return " do
      fname = File.dirname(__FILE__) + "/fixtures/test_ballot_1.tif"
      @result = {:filename => fname }
      upstream = flexmock("upstream")
      upstream.should_receive(:ann_offset, :ann_rect)
      upstream.should_receive(:ann_point)
      upstream.should_receive(:info)    
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
#      @bi.diagnostics :intermediate_images
      @bi.locate_ballot
      assert_between 0.0, 0.4, @bi.angle
      assert_between 0.0, 20.0, @bi.top_left.distance(BPoint.new(19, 19))
    end
    
    should "Find the voted ovals" do
      @bi.locate_ballot
      @bi.raw_marked_votes = []
      @bi.analyze_vote_ovals
    end

  end
  
  context "Working on test balot2" do
    setup do
      upstream = flexmock("upstream")
      upstream.should_receive(:ann_offset, :ann_rect)
      upstream.should_receive(:ann_rect)
      upstream.should_receive(:ann_point)

      assert upstream.ann_offset(1,2).nil?
      @bi = PbAnalyzer2.new(upstream)
      @bi.target_dpi = 200
#      @bi.diagnostics :intermediate_images
      filename = File.dirname(__FILE__) + "/fixtures/test_ballot_2.tif"
      @bi.open_ballot_image :ballot, filename, @bi.target_dpi
    end
    
    should "Find a reasonable origin and angle" do
      @bi.locate_ballot
      assert_between 0.0, 0.7, @bi.angle
      assert_between 0.0, 20.0, @bi.top_left.distance(BPoint.new(19, 18))
    end
    
    should "Find the voted ovals" do
      @bi.locate_ballot
      @bi.raw_marked_votes = []
      @bi.analyze_vote_ovals
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
  
  def common_setup filename, name
    filename = File.dirname(__FILE__) + filename 
    @upstream = ImageMagickUpstreamReporter.new(false, false, true)
    @upstream.ann_begin(filename, name)
    @bi = PbAnalyzer2.new(@upstream)
    @bi.target_dpi = 200
    @bi.open_ballot_image :ballot, filename, @bi.target_dpi
  end
  
  def common_gen_ann_image name
    @bi.locate_ballot
    @bi.raw_marked_votes = []
    @bi.raw_barcode = []
    @bi.analyze_vote_ovals
    @bi.analyze_barcode
    @upstream.ann_done(name)    
  end
  
  context "Analyze list of test ballots" do
    setup do
      @list = [["/fixtures/test_ballot_1.tif", "b1", [0, 1, 16, 26, 28, 29, 32, 33], [[32, 2]]],
               ["/fixtures/test_ballot_2.tif", "b2", [0, 2, 3, 4, 5, 7, 8, 9, 10, 14, 15, 20, 24, 26, 27, 30, 33], []],
               ["/fixtures/test_ballot_3.tif", "b3", [0, 1, 16, 26, 28, 29, 32, 33],[[30, 2]] ],
               ["/fixtures/test_ballot_4.tif", "b4", [0, 1, 16, 26, 29, 33], [[36, 2]] ],
               ["/fixtures/test_ballot_5.tif", "b5", [0, 1, 16, 26, 28, 29, 32, 33], [[26, 2]]],
               ["/fixtures/test_ballot_069.tif", "069", [0, 1, 16, 26, 28, 29, 32, 33], [[38, 2]]],
               ["/fixtures/test_ballot_124.tif", "124", [0, 2, 3, 4, 5, 7, 8, 9, 10, 14, 15, 20, 24, 26, 27, 30, 33], []],
               ["/fixtures/test_ballot_423.tif", "423", [0, 1, 16, 26, 28, 29, 32, 33],[[30, 2]]],
               ["/fixtures/test_ballot_409.tif", "409", [0, 1, 16, 26, 28, 29, 32, 33], [[30, 2]]],
               ["/fixtures/test_ballot_002.tif", "002", [0, 2, 3, 4, 5, 7, 8, 9, 10, 14, 15, 20, 24, 26, 27, 30, 33], []]               
               ]
    end
    
    should "should match expected results" do
      @list.each do
        |filename, id, correct_barcode, correct_votes|
          common_setup filename, id
          common_gen_ann_image id
          assert_equal correct_barcode, @bi.raw_barcode, "#{id}: incorrect barcode: "
          assert_equal correct_votes, @bi.raw_marked_votes, "##{id}: incorrect votes: "
          assert_nothing_raised  "#{id}: sanity check failed" do
            @bi.sanity_check
          end          
      end
    end
    
    should "annotate  test_ballot_3" do
      common_setup "/fixtures/test_ballot_3.tif", "test_ballot_3"
      common_gen_ann_image "test_ballot_3"
      assert_equal [0, 1, 16, 26, 28, 29, 32, 33], @bi.raw_barcode
      assert_equal [[30, 2]], @bi.raw_marked_votes
      assert_nothing_raised do
        @bi.sanity_check
      end
    end
  end
  
  context "Working on ballot under microscope" do
    should "analyze and annotate it" do
      common_setup "/fixtures/test_ballot_3.tif", "microscope"
      @bi.diagnostics :intermediate_images
      common_gen_ann_image "microscope"
      puts "microscope: barcode: #{@bi.raw_barcode.inspect}, votes: #{@bi.raw_marked_votes.inspect}"      
    end
  end
end