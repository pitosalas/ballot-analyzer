#!/usr/bin/env ruby
=begin
  * Name: ba-run
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
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require 'rubygems'
require 'getoptlong'
require 'ba'
require 'yaml'
require 'logger'


class BARun
  def initialize
    # make sure that output to stdout goes right out and doesnt get collected and bufferred
    $stdout.sync = true
  end
  
  def parse_commandline
    parser = GetoptLong.new
    parser.set_options(
                    ["-h", "--help", GetoptLong::NO_ARGUMENT],
                    ["-t", "--test", GetoptLong::NO_ARGUMENT],
                    ["-v", "--version", GetoptLong::NO_ARGUMENT],
                    ["-l", "--log", GetoptLong::NO_ARGUMENT],
                    ["-u", "--upstream", GetoptLong::NO_ARGUMENT],
                    ["-r", "--result", GetoptLong::REQUIRED_ARGUMENT],
                    ["-f", "--file", GetoptLong::REQUIRED_ARGUMENT], 
                    ["-d", "--directory", GetoptLong::REQUIRED_ARGUMENT ])
    
    @action = :none
    @style = :none
    @result = :none
    loop do
      begin
        opt, arg = parser.get
        break if not opt
        case opt
          when "-h"
            puts "Usage: ha! Read the code, silly :)"
            @action = :nothing
          break
            when "-t"
            @action = :test
          when "-v"
            puts "Version 0.0"
            @action = :nothing
            break
          when "-d", "-f"
          if @style == :none
            @action = :run
            @style = opt == "-d" ? :directory : :file
            @path = arg
          else
            puts "Cannot specify more than one of -d and -f"
          end
          when "-u"
            @action = :run
            @upstream = true
          when "-l"
            @logging = true
          when "-r"
            puts arg
            @result = arg
        end
      end
    end    
  end
  
  #
  # Based on options, invoke the right code
  #
  
  def dispatch
    if @action == :test
      do_test_mode
    elsif @action == :run
      do_run_mode
    end
  end
end

def do_test_mode
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

def do_run_mode
  inparams = {   :upstream => UpstreamReporter.new(@upstream, @logging),
                 :target_dpi => 200,
                 :max_skew => 0.08,
                 :path_style => @style,
                 :path => @path}
  
  outparams = []
  processor = PbProcessor.new inparams, outparams
  processor.process
  if @logging
    puts outparams.to_yaml if @logging
  end
  if @result != :none
    puts @result
    File.open(@result, "w") { |f| f << outparams.to_yaml }
  end
end


ba_run = BARun.new
ba_run.parse_commandline
ba_run.dispatch
