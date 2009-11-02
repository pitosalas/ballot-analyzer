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
  TopExtent = 3/4.0         # How tall the top zone (with timing marks) is assumed to be
  LeftExtent = 3/8.0         # How wide the left zone (with timing marks) is assumed to be
  RightExtent = 3/8.0       # How wide the RIGHT zone (with timing marks) is assumed to be
  
#
# A off all the posible coordinate pairs, the hot columns are the ones that MIGHT contain an
# oval to be checked. The other ones are in the margins, or in other impossible places.
#
  Hot_columns = [2, 13, 24]
  Hot_rows = Array.new(50-7-1) {|x| x + 7}

  def initialize up_stream
    super(up_stream)
  end
  
  attr_accessor :raw_marked_votes

  
#
# Analyze a Premier Ballot. Main worker.
#
  def analyze_ballot_image filename, dpi, result, upstream
    @raw_barcode = []
    @raw_marked_votes = []
    @filename = filename
    @upstream = upstream
    @upstream.info "Premier Ballot2: Processing #{filename}, Target DPI=#{target_dpi}"
    self.target_dpi = dpi
    open_ballot_image :ballot, filename, dpi
    locate_ballot
    result[:raw_barcode] = @raw_barcode
  end


#
# Analyze the image to determine the skew and origin. This is done by analyzing the three 
# fixed sets of marks, along the top, left and right. Each one will yield an opinion of where the pixel 
# coordinates of the origin and the degress of rotation of the ballot. We use those three
# to come up with a majority vote.
#
  def  locate_ballot
    
    # create an array containing the three results from the locate_marks calls.
    results = [locate_marks(:top, :ballot, TopExtent),
               locate_marks(:left, :ballot, LeftExtent),
               locate_marks(:right, :ballot, RightExtent)]

    # resolve, based on some heuristic, what we believe to be the actual origin and angle
    self.ballot_origin, self.ballot_angle = resolve_location(results)
    @upstream.ann_point(self.ballot_origin.x, self.ballot_origin.y, 10)
  end

#
# Come up with the origin and rotation that we will actually rely on based on a set of
# estimates from the 3 different strategies for figuring that out.
# <tt>locations</tt>::  array of [origin, angle] pairs, or nil, in case a strategy failed
#
# returns
#   [origin, angle]::   result of resolving the votes
#
  def resolve_location locations
    locations.compact!
    votes = locations.length
    raise "Cannot figure out ballot" if votes == 0
    angle_total = 0
    x_total = 0
    y_total = 0
    locations.each do 
      |angle_origin_pair|
        angle_total += angle_origin_pair[1]
        x_total += angle_origin_pair[0].x
        y_total += angle_origin_pair[0].y
    end
    angle = angle_total / votes
    origin = BPoint.new(x_total/votes, y_total/votes)
    [origin, angle]
  end

#
# Walk through all the potential locations for vote ovals.where the vote oval would be, and then analyze it.
#
  def analyze_vote_ovals
    Hot_columns.each do |col_index|
      Hot_rows.each do |row_index|
        vote_oval_pos = transform_point(BPoint.new(col_index, row_index))
        @upstream.ann_point(vote_oval_pos.x, vote_oval_pos.y)
        score = inspect_checkbox :ballot, vote_oval_pos.x - i2p(Vote_oval_width)/2.0, vote_oval_pos.y-i2p(Vote_oval_height)/2.0, i2p(Vote_oval_width), i2p(Vote_oval_height)
        if score < (QuantumRange * 0.7).to_int then
          m_trace "r: #{row_index}, c: #{col_index} -> #{score}"
          @raw_marked_votes << [row_index, col_index]
        end
      end
    end
  end

#
# Apply appropriate transformations for rotation, origin and units to a point specified in the 'timing mark' coordiante
# system, to come up with the actual location in image pixels.
# <tt>point</tt>:: BPoint in 'timing mark' coordinate system
# Returns:
# :: BPoint in image pixel coordinates.
#
  def transform_point(point) 
  # here: col_index and row_index of the potential vote oval, using the 'timing mark' coordinate system
    ballot_coord = point_b2i(point)
  # here: ballot_coord is the position of the vote oval, in inches from the origin
    bc_in_pixels = BPoint.new(i2p(ballot_coord.x), i2p(ballot_coord.y))
  # here: now bc is in pixel coordinates, still off the ballot origin (vs. the image orign)
    bc_physical = bc_in_pixels.offset(self.ballot_origin) 
  # here: bc_physical is the position of the vote oval, after accounting for the offset of the origin from pixel(0,0)
    bc_rotated = bc_physical.rotate BPoint.deg_to_rad(self.ballot_angle)     
  # here: rotated_bc is the position of the vote oval in inch coordinates from the origin, after accounting for rotation
    bc_corrected = BPoint.new(bc_rotated.x+i2p(TM_Width/2.0), bc_rotated.y+i2p(TM_Height/2.0))
  # here: bc_corrected is the position of the center of the target vote oval
    return bc_corrected
  end
  
#
# Given a BPoint in ballot coordinates (i.e. indexed by timing mark position), return a BPoint in inches
# without applying ballot skew (rotation) or origin (offset) corrections
#
# <tt>coord</tt>::  BPoint of the source coordinates
#
# Returns:: BPoint of the result coordinats, in inches
#
  def point_b2i(coord)
    raise ArgumentError, "b2i expects a BPoint" unless coord.class == BPoint
    raise ArgumentError, "b2i Point coord out of bounds" unless coord.x < TM_Top_Count && coord.y < TM_Sides_Count
    BPoint.new(coord.x * (TM_Width+TM_H_Space), coord.y * (TM_Height+TM_V_Space)) 
  end
end


