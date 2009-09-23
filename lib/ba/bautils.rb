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

require 'pathname'

#
# Directory Walker, provides various fancy ways of traversing files in directories
#
class DirectoryWalker
  
  def initialize
  end
  
  def walk_directory directory
    Dir.foreach(Pathname.new(directory)) do |l1_name|
      begin
        next if l1_name[0] == 46
        filename = Pathname(directory) + l1_name
        yield filename
      rescue => err
#        puts "ERROR: processing #{filename}: #{err}, #{err.backtrace[0]}"
      end
    end    
    
    def walk_2level_path l1_path 
      Dir.foreach(Pathname.new(l1_path)) do |l1_name|
        begin
          next if l1_name[0] == 46                 # skip . and ..
          l2_path = Pathname.new(l1_path) + l1_name
          if l2_path.directory?
            Dir.foreach(l2_path) do |l2_name|
              begin
                next if l2_name[0] == 46             # skip . and ..
                current_file = Pathname(l2_path) + l2_name
                yield current_file
              rescue => err
#                puts "ERROR: processing #{current_file}: #{err}, #{err.backtrace[0]}"
              end
            end
          else
#            puts "Skipping #{l2_path}"
          end
        rescue => err
#          puts "processing #{l1_path}: #{err}, #{err.backtrace[0]}"
        end
      end
    end    
    
  end
end