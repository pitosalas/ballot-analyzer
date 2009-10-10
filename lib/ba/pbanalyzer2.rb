=begin
  * Name: pbanalyzer.rb
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

class PbAnalyzer2 < PbCommonAnalyzer
  
#
# Key measurements, in inches
#
  TopZoneHeight = 1.5
  LeftZoneWidth = 0.5
  RightZoneWidth = 0.5

  def initialize up_stream
    super(up_stream)
  end
  
#
# Analyze a Premier Ballot. Main worker.
#
  def analyze_ballot_image filename, dpi, max_skew, result, upstream
    @raw_barcode = []
    @raw_marked_votes = []
    @filename = filename
    @up = upstream
    @up.info "Premier Ballot2: Processing #{filename}, Target DPI=#{target_dpi}"
    self.target_dpi = dpi
    open_ballot_image
    calculate_ballot_skew
    result[:raw_barcode] = @raw_barcode
  end

# 
# do any needed conditioning on the image and open it.
#
  def open_ballot_image
    open_image :ballot, @filename, @target_dpi
    d_write_image :ballot
  end
  
#
# Analyze the image to determine the skew and offset
#
  def calculate_ballot_skew
    top_offset, top_angle = locate_marks :top, :ballot, TopZoneHeight
    left_offset, left_angle = locate_marks :left, :ballot, LeftZoneWidth
    right_offset, right_angle = locate_marks :right, :ballot, RightZoneWidth
    
    puts "top offset #{top_offset}, angle #{top_angle}"
    puts "right offset #{left_offset}, angle #{left_angle}"
    puts "right offset #{right_offset}, angle #{right_angle}"
  end

end
