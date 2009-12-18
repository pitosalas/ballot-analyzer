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

=end

require 'ba/bautils'

class PbAnalyzer2 < PbCommonAnalyzer
  
#
# Key measurements, in inches
#
  TopExtent = 3/8.0         # How tall the top zone (with timing marks) is assumed to be
  LeftExtent = 3/8.0        # How wide the left zone (with timing marks) is assumed to be
  RightExtent = 3/8.0       # How wide the RIGHT zone (with timing marks) is assumed to be
  
#
# A off all the posible coordinate pairs, the hot columns are the ones that MIGHT contain an
# oval to be checked. The other ones are in the margins, or in other impossible places.
#
  Hot_columns = [2, 13, 24]
  Hot_rows = Array.new(50-7-1) {|x| x + 7}
  
  Barcode_Columns = TM_Top_Count
  Barcode_Row = TM_Sides_Count
  
#
# Detection Thresholds: 0 - pure black, 1 = pure white
#
  BarCodeDetectThresh = 0.65 # How black does a barcode have to be to count? 
  VoteOvalDetectThresh = 0.50 # How black does a vote checkmark have to be to count?

# 
# PBAnalyzer2 object is used for a series of ballot analyses. Here we initialize state
# which is needed for the whole object. 
# <tt>up_stream</tt>:: upstream reporter object.
  def initialize up_stream
    super(up_stream)
  end
  
#
# Reset things for the next ballot
#
# <tt>filename</tt>:: path to ballot
# <tt>dpi</tt>:: desired dpi. ballot is scaled to this dpi (TODO: what does this really do?)
# <tt>result</tt>:: Hash which will receive the result of scanning one ballot
# <tt>upstream</tt>:: upstream reporting object (TODO: why is this repeated?)
  def reset_analyzer filename, dpi, result, upstream
    @raw_barcode = []
    @raw_marked_votes = []
    @filename = filename
    @upstream = upstream
    @upstream.info "Premier Ballot2: Processing #{filename}, Target DPI=#{dpi}"
    self.target_dpi = dpi  
  end

#
# Clean up and pull out whatever result the object state and store it in the results hash
# <tt>results</tt>::  results hash
  def compile_results results
    def @raw_barcode.to_yaml_style; :inline; end
    def @raw_marked_votes.to_yaml_style; :inline; end
    result[:raw_barcode] = @raw_barcode
    result[:raw_marked_votes] = @raw_marked_votes
  end
  
  attr_accessor :raw_marked_votes, :raw_barcode
 
#
# Analyze a Premier Ballot. Main worker.
#
# <tt>filename</tt>:: path to ballot
# <tt>dpi</tt>:: desired dpi. ballot is scaled to this dpi (TODO: what does this really do?)
# <tt>result</tt>:: Hash which will receive the result of scanning one ballot
# <tt>upstream</tt>:: upstream reporting object (TODO: why is this repeated?)
#
  def analyze_ballot_image filename, dpi, result, upstream
    reset_analyzer filename, dpi, result, upstream
    open_ballot_image :ballot, filename, dpi
    locate_ballot
    sanity_check_ballot_coords
    analyze_vote_ovals
    analyze_barcode
    sanity_check
    compile_results result
  end

#
# Analyze the image to determine the skew and origin. This is done by analyzing the three 
# fixed sets of marks, along the top, left and right. Each one will furnish information about
# both the placement and the angle of the ballot. The end result of this method is the best guess
# for @topleft, @bottomleft, @topright, @bottomright and @angle
#
  def  locate_ballot
    
    topmarks = locate_marks(:top, :ballot, TopExtent)
    leftmarks = locate_marks(:left, :ballot, LeftExtent)
    rightmarks = locate_marks(:right, :ballot, RightExtent)

# The angle of the ballot is simply the average of the non-nil angles returned from the three marks (note that )
# the returned angle will be nil if locate_marks can't figure it out'
    angles = [topmarks.angle, leftmarks.angle, rightmarks.angle].compact
    self.angle  = angles.inject {|total, x| total+x}/angles.length
    
# Determimne the 4 corners of the ballot. Some info is redundant, so if it's not found in one place, we try other places. 
# We create a list of all the candidates for each one, in order of preference, and then in a 
# separate pass we decide which one is the best match

    top_left_x = [] << topmarks.firstmark.x << leftmarks.firstmark.x
    top_left_y = [] << topmarks.firstmark.y << leftmarks.firstmark.y
    bottom_left_x = [] << leftmarks.lastmark.x << leftmarks.firstmark.x << topmarks.firstmark.x
    bottom_left_y = [] << leftmarks.lastmark.y << rightmarks.lastmark.y
    top_right_x = [] << topmarks.lastmark.x << rightmarks.firstmark.x
    top_right_y = [] << topmarks.lastmark.y << rightmarks.firstmark.y << topmarks.firstmark.y << leftmarks.firstmark.y
    bottom_right_x = [] << rightmarks.lastmark.x << topmarks.lastmark.x
    bottom_right_y = [] << rightmarks.lastmark.y << leftmarks.lastmark.y
    
    self.top_left = BPoint.new(top_left_x.detect {|x| !x.nil?}, top_left_y.detect {|x| !x.nil?})
    self.bottom_left = BPoint.new(bottom_left_x.detect {|x| !x.nil?}, bottom_left_y.detect {|x| !x.nil?})
    self.top_right= BPoint.new(top_right_x.detect {|x| !x.nil?}, top_right_y.detect {|x| !x.nil?} )
    self.bottom_right = BPoint.new(bottom_right_x.detect {|x| !x.nil?}, bottom_right_y.detect {|x| !x.nil?})
    
    @upstream.ann_point(self.top_left.x, self.top_left.y, 10)
    @upstream.ann_point(self.top_right.x, self.top_right.y, 10)
    @upstream.ann_point(self.bottom_left.x, self.bottom_left.y, 10)
    @upstream.ann_point(self.bottom_right.x, self.bottom_right.y, 10)

  end


#
# Walk through all the potential locations for vote ovals.where the vote oval would be, and then analyze it.
#
  def analyze_vote_ovals
    Hot_columns.each do |col_index|
      Hot_rows.each do |row_index|
        vote_oval_pos = transform_point(BPoint.new(col_index, row_index))
        @upstream.ann_point(vote_oval_pos.x, vote_oval_pos.y)
        xpos = vote_oval_pos.x - i2p(Vote_oval_width)/2.0
        ypos = vote_oval_pos.y-i2p(Vote_oval_height)/2.0
        width = i2p(Vote_oval_width)
        height = i2p(Vote_oval_height)
        @upstream.ann_rect(xpos, ypos, width, height)
        score = shrink_to_one :ballot, xpos, ypos, width, height
        if score < (QuantumRange * VoteOvalDetectThresh).to_int then
          @raw_marked_votes << [row_index, col_index]
        end
      end
    end
  end
  
#
# Walk through the barcode, and record whether each 'tic' is on or off
#
  def analyze_barcode
      Barcode_Columns.times do |barcode_col_index|
        barcode_pos = transform_point(BPoint.new(barcode_col_index, Barcode_Row-1), :bottombias)
        @upstream.ann_point(barcode_pos.x, barcode_pos.y)
        score = shrink_to_one(:ballot, barcode_pos.x - i2p(TM_Width)/2.0, barcode_pos.y-i2p(TM_Height)/2.0, i2p(TM_Width), i2p(TM_Height))
        if score < (QuantumRange * BarCodeDetectThresh).to_int then
          @raw_barcode << barcode_col_index
        end
      end
  end
  
#
# Sanity check raw votes and raw barcodes. There are certain things we know about the results
# even before we tell one ballot style from another. This method will sort that out.
#
  def sanity_check
    @raw_barcode.include?(0) && @raw_barcode.include?(Barcode_Columns-1)
  end
  
# 
# Sanity check the ballot coordiantes, in other words, did we reasonably detect the 4 corners? If not
# there's no point in continuing.
  def sanity_check_ballot_coords
    
  end

#
# Apply appropriate transformations for rotation, origin and units to a point specified in the 'timing mark' coordiante
# system, to come up with the actual location in image pixels.
# <tt>point</tt>:: BPoint in 'timing mark' coordinate system
# Returns:
# :: BPoint in image pixel coordinates.
#
  def transform_point(point, bias=nil) 
  # here: col_index and row_index of the potential vote oval, using the 'timing mark' coordinate system
    bc_fractional = point_b2f(point)
  # here: ballot_coord is the position of the vote oval, in ballot fraction coordinates
    if bias == :bottombias
      bc_in_pixels = point_f2p_bottom_bias(bc_fractional)
    else
      bc_in_pixels = point_f2p(bc_fractional)
    end

  # here: bc_in_pixels is the position of the vote oval, after accounting for the offset of the origin from pixel(0,0)
  #  bc_rotated = bc_in_pixels.rotate BPoint.deg_to_rad(self.angle)  
  # here: rotated_bc is the position of the vote oval in inch coordinates from the origin, after accounting for rotation
    bc_corrected = BPoint.new(bc_in_pixels.x+i2p(TM_Width/2.0), bc_in_pixels.y+i2p(TM_Height/2.0))
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
    raise DeprecatedError, "method: point_b2i deprecated"
    raise ArgumentError, "b2i expects a BPoint" unless coord.class == BPoint
    raise ArgumentError, "b2i Point coord out of bounds" unless coord.x < TM_Top_Count && coord.y < TM_Sides_Count
    BPoint.new(coord.x * (TM_Width+TM_H_Space), coord.y * (TM_Height+TM_V_Space)) 
  end
  
#
# Given a BPoint in ballot coordinates (i.e. indexed by timing mark position), return a BPoint where the coords
# are floats, 0<x<1.0 representing the fraction of the distance between in the 'ballot field' which is the space demarkated
# between the first and last timing mark.
# <tt>coord</tt>::  BPoint of the source coordinates
# Returns:: BPoint of the result coordinats, as a fraction
#
  def point_b2f(coord)
    raise ArgumentError, "b2i expects a BPoint" unless coord.class == BPoint
    raise ArgumentError, "b2i Point coord out of bounds" unless coord.x < TM_Top_Count && coord.y < TM_Sides_Count
    BPoint.new(coord.x / (TM_Top_Count-1.0), coord.y / (TM_Sides_Count-1.0))
  end
  
#
# Given a BPoint in fractional coordinates (a coordinate between 0.0 <= c < 1.0, which says how far between a pair of 
# edges of the ballot zone.) compute the corresponding position in pixels.
#
# <tt>coord</tt>::  Fractional coordinate of a point
# Returns:: BPoint of that point, in pixels
#
  def point_f2p_new(coord)
    begin
      x = coord.x * (@top_right.x - @top_left.x) + coord.y * (@bottom_left.x - @top_left.x) + @top_left.x
      y = coord.x * (@top_right.y - @top_left.y) + coord.y * (@bottom_left.y - @top_left.y) + @top_left.y
      BPoint.new(x, y)
    rescue
      BPoint.new(0,0)
    end
  end
  
    
  def point_f2p(coord)
    begin
      x = coord.x * (@top_right.x - @top_left.x) + @top_left.x
      y = coord.y * (@bottom_left.y - @top_left.y) + @top_left.y
      BPoint.new(x, y)
    rescue
      BPoint.new(0,0)
    end
  end
  
  def point_f2p_bottom_bias(coord)
    begin
      x = coord.x * (@bottom_right.x - @bottom_left.x) + @bottom_left.x
      y = coord.y * (@bottom_left.y - @top_left.y) + @top_left.y
      BPoint.new(x, y)
    rescue
      BPoint.new(0,0)
    end
  end

end




