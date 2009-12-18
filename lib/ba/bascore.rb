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
=end

class PBScorer
  
  attr_accessor :raw_data_hash
  attr_reader :success_count, :failed_count, :total_count, :results, :tabulation_failed, :tabulation_count
  
  def initialize
    @ballot_style_map = nil
    @raw_data_hash = nil
    @results = BallotInfo.new
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

#
# Iterate over the all the 'choices' in the abllot style map
#
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

#
# Iterate over all the contests in the ballot style map
#
  def each_contest_in_map 
    @ballot_style_map.each do
       |precinct_code, precinct_map |
       contest_list = precinct_map[:coords]
       contest_list.each { |contest| yield contest[:contest] }
     end
   end
 
#
# Iterate over all the precinct names in the balot style map
# 
   def each_precinct_in_map
     @ballot_style_map.each do
       |precinct_code, precinct_map|
       yield precinct_map[:name]
     end
   end
  
 #
 # Translate a pair of ballot coordinates of a vote (on a certain ballot type) into the corresponding
 # Contest name and Choice in that contest
 # Returns::  [name of contest, choice in contest]
 #
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
  
#
# Load the yaml file with the raw results of the ballot scanner into memory 
# for futher analysis. The file contains a series of records, one for each ballt.
#
# <tt>filename</tt>:: File containing the raw results.
   
  def load_raw_data filename
    File.open(filename) { |file| @raw_data_hash = YAML.load file }
    @total_count = @raw_data_hash.length
    @failed_count = 0
    @tabulation_count = 0
    @tabulation_failed = 0
    @raw_data_hash.each do |e|
      if e[:status] == :failure
        @failed_count = @failed_count + 1
      elsif e[:status] != :success
        throw "unexpected :status in raw rata"
      end
    end
    @success_count = @total_count - @failed_count
  end

#
# Given 'raw' ballot style barcode, look up in the ballot style map to come up with
# the decoded or actual ballot style code.
# <tt>raw_style</tt>::  number extracted from the barcode, e.g. "1" or "12"
# returns:: named ballot style, e.g. "G121-4"
  def ballot_style_decode raw_style
    if !@ballot_style_map.has_key? raw_style
      raise "unknown ballot style #{raw_style}, #{@ballot[:filename]}"
    end
    @ballot_style_map.fetch(raw_style)
  end
  
#
# Process an individual ballot and add information to the hash based on it's decoding. The result is a modification
# of @raw_data_hash, and adding totals.
#<tt>record_num</tt>::  Record (ballot) number
#
  def annotate_raw_data record_num    
    raise "invalid record requested" unless @raw_data_hash.length >= record_num
    @curr_ballot = @raw_data_hash[record_num]
    return false if @curr_ballot[:status] == :failure
    
    if !@curr_ballot.has_key? :ballot_style
      raise "unknown ballot style"
    end
    precinct_map = ballot_style_decode @curr_ballot[:ballot_style]
    precinct = precinct_map[:name]

    if !@results.precinct? precinct
      raise "unknown precinct #{precinct}"
    end
   
    coord_map = precinct_map[:coords]
    vote = Struct.new(:contest, :choice)
    @curr_ballot[:coded_marked_votes] = []
    @curr_ballot[:raw_marked_votes].each do
      |raw_mark|  
        contest, choice = vote_oval_coord_decode coord_map, raw_mark        
        if contest.nil? || choice.nil?
          raise "unrecognized mark on ballot # #{record_num}: prec=#{precinct}, mark: #{raw_mark.inspect}, in file: #{@curr_ballot[:filename].inspect}" 
        end
        @curr_ballot[:precinct] = precinct
        @curr_ballot[:coded_marked_votes] << vote.new(contest, choice)
    end
  end
  
#
# Process a single 'record' from the raw data for the ballot analysis that we are working on.
#<tt>record_number::  a number between 0 and the number of ballots represented.
#
  def process_record record_number
    begin
      annotate_raw_data(record_number)
      if @curr_ballot.has_key?(:coded_marked_votes)
        full_filenm = @curr_ballot[:filename]
        filenm = /(\w+).tif/.match(full_filenm)[1]
        @curr_ballot[:coded_marked_votes].each do |mark| 
          @results.add_to_count @curr_ballot[:precinct], filenm, mark.contest, mark.choice, 1
        end
        @tabulation_count = @tabulation_count + 1
        result = true
      end
    rescue Exception => ex
        @tabulation_failed = @tabulation_failed + 1
        @curr_ballot[:exceptions] = ex.to_s
        result = false
    end
    result
  end

#
# Simply run through all the raw data records and process them
#
  def process_all_records
    @total_count.times  { |index| process_record index }
  end
  
#
# Generate a csv file of the raw barcode data for import into Excel and analysis
# Returns a string with the csv, suitable for printing or saving to a file. This is 
# useful in order to further figure out bar codes.
#
  Csv_row = Struct.new(:count, :filenames, :fronts, :backs)
  def barcode_csv
    csv_rows = {}
    collect = []
    total_count.times do
      |index|
      ballot_info = raw_data_hash[index]
      expanded_barcode = Array.new(34, 0)
      ballot_info[:raw_barcode].each { |val| expanded_barcode[val] = 1 }
      if !csv_rows.has_key? expanded_barcode
        csv_rows[expanded_barcode] = Csv_row.new
        csv_rows[expanded_barcode].count = 0
        csv_rows[expanded_barcode].filenames = ""
        csv_rows[expanded_barcode].fronts = 0
        csv_rows[expanded_barcode].backs = 0
      end
      csv_row = csv_rows[expanded_barcode]
#
# Now: ballot_info has raw image analysis for ballot "index"
#     expanded_barcode is an array with 1's at the indexes where the barcode had a bar, and zeros elsewhere
#     csv_rows contains an instance of the struct Csv Row corresponding to the barcode of this ballot
#
# Count a ballot with this barcode, add the file name to list, increment count of fronts vs. backs
#
      csv_row.count += 1
      filenm = ballot_info[:filename]
      filenm = /(\d\d\d).tif/.match(filenm)[1]
      csv_row.filenames << filenm+", "
      filenm_num = filenm.to_i
      collect << filenm_num
      if filenm_num / 2 == filenm_num / 2.0
        csv_row.backs += 1
      else
        csv_row.fronts += 1
      end
    end
#
# Now just dump out the csv_rows into a csv file
#
    csv = FasterCSV.generate do |c|
      csv_rows.each_pair do
        |key, value|
        c << [value.count, value.fronts, value.backs, value.filenames, key].flatten
      end
    end
    432.times { |x| puts x if !collect.contains? x}  
    csv
 end

end
