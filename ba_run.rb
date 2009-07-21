=begin
  * Name: Ballot-analyzer
  * Description: Analyze voting ballots
  * Author: Pito Salas
  * Copyright: (c) R. Pito Salas and Associates, Inc.
  * Date: January 2009
  * License: GPL

  This file is part of Ballot-analyzer.

  Ballot-analyzer is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Ballot-analyzer is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Ballot-analyzer.  If not, see <http://www.gnu.org/licenses/>.

  require "ruby-debug"
  Debugger.settings[:autolist] = 1 # list nearby lines on stop
  Debugger.settings[:autoeval] = 1
  Debugger.start
=end

require 'lib/iadsl.rb'
require 'lib/pbprocessor.rb'
require 'lib/pbanalyzer.rb'
require 'lib/bautils'
require 'yaml'
require 'logger'

inparams = {:forensics => :on, 
            :logging => :on, 
            :target_dpi => 100,
            :max_skew => 0.15,
            :dir_style => :two_level,
            :path => "/mydev/ballot-analyzer/test/images/twolevel/"}

outparams = []
processor = PbProcessor.new inparams, outparams
processor.process_2level_directory_structure
puts outparams.to_yaml









