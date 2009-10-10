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
  context "A brand new BallotInfo, without upstream set" do
    setup do
      @bi = PbAnalyzer2.new(nil)
    end
    
    should "say hello to world" do
      assert true
    end
    
    should "processing an image should always return " do
      fname = File.dirname(__FILE__) + "/fixtures/432Leon200dpibw001.tif"
      @result = {:filename => fname }
      upstream = flexmock("upstream")
      upstream.should_receive(:info).once
      @bi.analyze_ballot_image fname, 200, 0.1, @result, upstream
      assert @result.has_key? :raw_barcode
    end
  end
  
end