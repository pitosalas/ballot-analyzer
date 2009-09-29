=begin
  * Name: pbprocessor.rb
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

class PBScorer
  
  attr_accessor :raw_data_hash
  attr_reader :success_count, :failed_count, :total_count
  
  def initialize
    @ballot_style_map = nil
    @raw_data_hash = nil
    @results = BallotInfo.new
  end
  
  def results
    @results
  end
    
  def ballot_style_map= a_hash
    @ballot_style_map = a_hash
    initialize_result_ballot_info
  end

# 
# Initialize the BallotInfo results object based on the Ballot Style Map. Basically walk through
# the BallotStyleMap supplied and pull out key information to initialize the BallotInfo result
# structure.
#
  def initialize_result_ballot_info
    each_precinct_in_map { |p| @results.add_precinct p }
    each_contest_in_map { |c| @results.add_contest c }
    each_choice_in_map { |cont_n, choice_n| @results.add_contest_choice cont_n, choice_n }
  end

  def each_choice_in_map
    @ballot_style_map.each do
      |precinct_code, precinct_map |
      contest_list = precinct_map[:coords]
      contest_list.each do 
        |contest|
        contest_name = contest[:contest]
        contest[:choices].each do
          |addr, choicename|
          yield contest_name, choicename
        end
      end
     end
   end

  def each_contest_in_map 
    @ballot_style_map.each do
       |precinct_code, precinct_map |
       contest_list = precinct_map[:coords]
       contest_list.each { |contest| yield contest[:contest] }
     end
   end
   
  def vote_oval_coord_decode coord_map, coords
    coord_map.each do
      |contest| 
      contest_name = contest[:contest]
      choices = contest[:choices]
      choices.each do
        |mark, choice|
        if mark == coords
          return contest_name, choice
        end
      end
    end
    [nil, nil]
  end
  
   
   def each_precinct_in_map
     @ballot_style_map.each do
       |precinct_code, precinct_map|
       yield precinct_map[:name]
     end
   end
   
  def load_raw_data filename
    File.open(filename) { |file| @raw_data_hash = YAML.load file }
    @total_count = @raw_data_hash.length
    @failed_count = 0 
    @raw_data_hash.each do |e|
      if e[:status] == :failure
        @failed_count = @failed_count + 1
      elsif e[:status] != :success
        throw "unexpected :status in raw rata"
      end
    end
    @success_count = @total_count - @failed_count
  end
  

  def ballot_style_decode raw_style
    @ballot_style_map.fetch(raw_style)
  end
  

  def annotate_raw_data record_num    
    raise "invalid record requested" unless @raw_data_hash.length >= record_num
    rec = @raw_data_hash[record_num]
    return false if rec[:status] == :failure
    
    precinct_map = ballot_style_decode rec[:ballot_style]
    precinct = precinct_map[:name]

    if !@results.precinct? precinct
      raise "unknown precinct #{precinct}"
    end
   
    coord_map = precinct_map[:coords]
    vote = Struct.new(:contest, :choice)
    rec[:coded_marked_votes] = []
    rec[:raw_marked_votes].each do
      |raw_mark|  
        contest, choice = vote_oval_coord_decode coord_map, raw_mark        
        if contest.nil? || choice.nil?
          raise "unrecognized mark on ballot # #{record_num}: prec=#{precinct}, mark: #{raw_mark.inspect}, in file: #{rec[:filename].inspect}" 
        end
        rec[:precinct] = precinct
        rec[:coded_marked_votes] << vote.new(contest, choice)
    end
    rec
  end
  
  def process_record record_number
    annotated_rec = annotate_raw_data(record_number)
    if annotated_rec && annotated_rec.has_key?(:coded_marked_votes)
      annotated_rec[:coded_marked_votes].each do |mark| 
        @results.add_to_count annotated_rec[:precinct], mark.contest, mark.choice, 1
      end
    end
  end
  
  def process_all_records
    @total_count.times  { |index| process_record index }
  end
  
end
