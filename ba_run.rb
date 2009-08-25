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
require 'rubygems'
require 'getoptlong'
require 'yaml'
require 'logger'

require 'lib/iadsl.rb'
require 'lib/pbprocessor.rb'
require 'lib/pbanalyzer.rb'
require 'lib/bautils'

# make sure that output to stdout goes right out and doesnt get collected and bufferred
$stdout.sync = true

parser = GetoptLong.new
parser.set_options(
                   ["-h", "--help", GetoptLong::NO_ARGUMENT],
["-t", "--test", GetoptLong::NO_ARGUMENT],
["-v", "--version", GetoptLong::NO_ARGUMENT],
["-d", "--directory", GetoptLong::REQUIRED_ARGUMENT ])

action = false
loop do
  begin
    opt, arg = parser.get
    break if not opt
    case opt
      when "-h"
      puts "Usage: ..."
      action = :nothing
      break
      when "-t"
      action = :test
      break
      when "-v"
      puts "Version 0.0"
      valid = :nothing
      break
      when "-d"
      action = :run
      @directory = arg
    end
  end
end

if action == :test 
  puts "start"
  i = 0
  5.times do
    puts "ballot #{i}"
    delay = rand(5).to_i
    sleep delay
    i = i+1
  end
  puts "exit"
end

if action == :run
  inparams = {:forensics => :on, 
              :logging => :off, 
              :target_dpi => 100,
              :max_skew => 0.15,
              :dir_style => :simple,
              :path => @directory}
  
  outparams = []
  processor = PbProcessor.new inparams, outparams
  processor.process_directory
  puts outparams.to_yaml
end
