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
 
  context "Analyzing 432Leon200dpibw001.tif" do
    setup do
      upstream = flexmock("upstream")
      @bi = PbCommonAnalyzer.new(upstream)
      fname = File.dirname(__FILE__) + "/fixtures/432Leon200dpibw001.tif"
      @bi.open_image :test, fname, 200
      @bi.target_dpi = 200
      @bi.diagnostics :intermediate_images

    end
    
    should " will always return a zero or positive offset" do
      offset, angle = @bi.locate_marks :top, :test, 1.0
      assert offset >= 0
    end
  end
end
