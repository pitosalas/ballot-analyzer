=begin
  * Name: ballotinfo.rb
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

require 'fastercsv'

class BallotInfo
  attr_reader :data_table

  def initialize
    @data_table = []
    @contest_list = []
    @precinct_list = []
  end
  
  def add_contest contest_name
    @contest_list << contest_name
  end

  def add_precinct precinct_name
    @precinct_list << precinct_name
  end
  
  def contests
    @contest_list
  end
  
  def precincts
    @precinct_list
  end
  
  def add_contest_choice race, choice
    
  end
  
  def add_to_count precinct, filename, contest, choice, increment
    validate_coords(precinct, contest, choice)
    @data_table << [:jurisdiction, filename, precinct, contest, choice, increment]
  end
  
  def get_count precinct, contest, choice
    validate_coords(precinct, contest, choice)
    @match_records = @data_table.find_all do 
        |rec| rec[1] == precinct &&
              rec[2] == contest &&
              rec[3] == choice
     end
     @match_records.inject(0) { |sum, ent| sum = sum + ent[4] } 
  end

  def csv
    FasterCSV.generate do |c|
      @data_table.each { |row| c << row }
    end
  end
  
  def contest? a_contest
    @contest_list.include? a_contest
  end
  
  def precinct? a_precinct
    @precinct_list.include? a_precinct
  end
  
private
  def validate_coords(precinct, contest, choice)
    raise "no such contest" unless contest? contest
    raise "no such precinct" unless precinct? precinct
  end
  
end

class BallotInfoOld
  def initialize
    @ballotinfo = Hash.new
    @precinct_list = Array.new
  end

  def add_contest contest_name
    @ballotinfo[contest_name] = Hash.new
  end
  
  def add_precinct precinct_name
    @precinct_list << precinct_name unless @precinct_list.include? precinct_name
  end
  
  def contests
    @ballotinfo
  end
  
  def precincts
    @precinct_list
  end
  
  def add_contest_choice contest, choice
    raise "no such contest" unless @ballotinfo.key? contest
    @ballotinfo[contest][choice] = Hash.new
  end
  
  def add_to_count(precinct, contest, choice, increment)
    validate_coords(precinct, contest, choice)
    @ballotinfo[contest][choice][precinct] += increment
  end
  
  def get_count(precinct, contest, choice)
    validate_coords(precinct, contest, choice)
    @ballotinfo[contest][choice][precinct]
  end
  

  def contest? a_contest
    @ballotinfo.key? a_contest
  end
  
  def precinct? a_precinct
    @precinct_list.include? a_precinct
  end
  
  def choice? a_contest, a_choice
    @ballotinfo[a_contest].key? a_choice
  end
  
  private
  def validate_coords(precinct, contest, choice)
    raise "no such contest" unless contest? contest
    raise "no such precinct" unless precinct? precinct
    if !choice? contest, choice
      raise "no such choice: #{choice}"
    end
    @ballotinfo[contest][choice][precinct] = 0 unless @ballotinfo[contest][choice].key? precinct
  end
      
end