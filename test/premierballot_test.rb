=begin
  * Name: Ballot-analyzer
  * Description: Analyze voting ballots
  * Author: Pito Salas
  * Copyright: (c) R. Pito Salas and Associates, Inc.
  * Date: January 2009
  * License: GPL

  This file is part of GovSDK.

  GovSDK is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  GovSDK is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with GovSDK.  If not, see <http://www.gnu.org/licenses/>.

  require "ruby-debug"
  Debugger.settings[:autolist] = 1 # list nearby lines on stop
  Debugger.settings[:autoeval] = 1
  Debugger.start
=end

require File.dirname(__FILE__) + '/test_helper'

class PremierBallotTest < Test::Unit::TestCase
  context "If should is properly setup then" do
    setup do
      @inparams = {:forensics => :on, :logging => :on, :target_dpi => 72, :max_skew => 0.15}
      @outparams = []
      @pb = PremierBallot.new @inparams, @outparams
    end

    should "succeed" do
      assert_equal 1,1
    end
    
    context "the test parameter validator" do
      setup do
        @par1 = {:key => 1, :string => "a"}
        @checkpar = {:key => Fixnum, :string => String }
      end
      
      should "accept simple valid param" do
        assert_equal true, @pb.valid_params?(@par1, @checkpar)
      end        
    end
  end
end
