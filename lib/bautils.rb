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

#
# Directory Walker, provides various fancy ways of traversing files in directories
#
class DirectoryWalker
  
  def initialize
    @logger = Logger.new(STDERR)
  end
    
  def walk_2level_path l1_path 
    Dir.foreach(Pathname.new(l1_path)) do |l1_name|
      begin
        next if l1_name[0] == 46                 # skip . and ..
        l2_path = Pathname.new(l1_path) + l1_name
        if l2_path.directory?
          @logger.warn "Processing directory #{l2_path}..."
          Dir.foreach(l2_path) do |l2_name|
            begin
              next if l2_name[0] == 46             # skip . and ..
              current_file = Pathname(l2_path) + l2_name
              yield current_file
            rescue => err
              @logger.error("Error working on #{current_file}: #{err}")
              @logger.error(err.backtrace.join("\n"))
            end
          end
        else
          @logger.warn("Skipping #{l2_path}")
        end
      rescue => err
        @logger.error("Error working on #{l1_path}: #{err}")
        @logger.error(err.backtrace.join("\n"))
      end
    end
  end    
end

