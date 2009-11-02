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
require 'ba/pbanalyzer'

class PbAbalyzerTest < Test::Unit::TestCase

  def assert_between(val1, val2, actual, message="")
    full_message = build_message(message, "<?> is expected to be between <?> and <?>.\n", actual, val1, val2)
    assert_block(full_message) { actual >= val1 && actual <= val2 }
  end

  context "A brand new BallotInfo without upstream set" do
    setup do
      @bi = PbAnalyzer.new(nil)
    end
    
    should "say hello to world" do
      assert true
    end
    
    should "processing an image should always return " do
      fname = File.dirname(__FILE__) + "/fixtures/test_ballot_1.tif"
      @result = {:filename => fname }
      upstream = flexmock("upstream")
      upstream.should_receive(:ann_offset)
      upstream.should_receive(:ann_point)
      upstream.should_receive(:ann_rect)
      upstream.should_receive(:info)
      @bi.diagnostics :intermediate_images
      @bi.analyze_ballot_image fname, 200.0, 1.0, @result, upstream
      assert @result.has_key? :raw_barcode
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
  
  def self.should_ann_image filename, name
    should "analyze and annotate #{filename}" do
      filename = File.dirname(__FILE__) + filename 
      @upstream = ImageMagickUpstreamReporter.new(false, false, true)
      @upstream.ann_begin(filename, name)
      @bi = PbAnalyzer.new(@upstream)
      result = Hash.new
      @bi.analyze_ballot_image filename, 200.0, 1.0, result, @upstream
      @upstream.ann_done(name)
    end
  end

  context "Test annotations on test ballots" do
    should_ann_image "/fixtures/test_ballot_1.tif", "b1-1"
    should_ann_image "/fixtures/test_ballot_2.tif", "b1-2"
    should_ann_image "/fixtures/test_ballot_3.tif", "b1-3"
  end

end