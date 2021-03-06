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

class PbCommonAnalyzer < IaDsl
# 
# These dimensions are all in inches. p2i() and i2p() convert back and forth between pixels and inches.
#
  TopwhiteMarginOffset = 1/32.0   # How much less than the detected white top margin we actualy remove
  EndRectSize = 1.0               # Size of the rectangle that is taken off a band to analyze skew
  TopWhiteMarginPeekBand = 1/8.0  # Height of strip of image that is analyzed at a time to find top margin, in inches 
  MinMarkHeight = 0.75 * 1/16.0   # Height of the shortest band of black that will be considered a timing mark
  MinMarkWidth = 0.5 * 2/16.0    # Widtht of the shortest band of black that will be considered a timing mark.
#
# These thresholds are in percent
#
  SideBandThresh = 40.0           # Threshold used for cleaning up Rect1 and Rect in analyzing the bars
  LongSideThresh = 80.0           # Threshold used for cleaning up Rect3 in analyzing the bars
#
# A series of thresholds that were determined empirically.
#
  ThreshRight1 = 80.0
  ThreshRight2 = 90.0
  ThreshLeft1 = 80.0
  ThreshLeft2 = 90.0
  ThreshLeft3 = 70.0
  ThreshTop3 = 90.0


#
# Dimensions of the Premier timing marks, in inches
#
  TM_Width = 3/16.0
  TM_Height = 1/16.0
  TM_H_Space = 1/16.0
  TM_V_Space = 3/16.0
  
  TM_Top_Count = 34
  TM_Sides_Count = 53

#
# Voting Oval dimensions
#
  Vote_oval_width = 1/4.0
  Vote_oval_height = 1/8.0
  
#
# Margin Peek Band Threshold
#
  MarginPeekThreshold =  0.8       # 1.0 is pure white. How white does the top area have to be to be considered part of margin


  attr_accessor :target_dpi, :top_left, :top_right, :bottom_left, :bottom_right, :angle

  def initialize up_stream
    super(up_stream)
  end

#
# Utility function that converts a geometric parameter specified in inches into what it would be in pixels.
# <tt>inches</tt>::  dimension in inches
# Returns dimension in pixels
#
  def i2p(inches)
    (inches * @target_dpi).to_i
  end
 
#
# Utility function that converts a geometric parameter specified in pixels to inches based on the dpi
#
#<tt>pixels</tt>::  dimension in pixels or a BPoint, with x and y being coordinates in pixels
# Returns dimension in inches
#
  def p2i(pixels)
    case pixels
    when Fixnum
      return (pixels * @target_dpi)
    when BPoint
      return BPoint.new(pixels.x * @target_dpi, pixels.y * @target_dpi)
    else 
      raise "p2i argument error"
    end
  end

# open the imaage and condition it.
#<tt>imageID</tt>:: imageid to be used for newly opened image
#<tt>filename</tt>:: filename where to find the image
#<tt>dpi</tt>:: desired dpi. If the image is not that dpi it is resampled. 
#
  def open_ballot_image imageId, filename, dpi
    self.target_dpi = dpi
    open_image imageId, filename, dpi

# Remove the top white margin by examining bands of pixels along the top until we find the first band that is not
# (close to) pure white. That is where the timing marks will be. Note that we are not insisting on pure white because
# there are often smudges and imperfections there.
#
    current_band_y = 0
    average_whiteness = QuantumRange
    band_pixels = i2p(TopWhiteMarginPeekBand)
    while average_whiteness > (QuantumRange * MarginPeekThreshold).to_int
      average_whiteness = shrink_to_one(imageId, 0, current_band_y, columns(imageId), band_pixels)
      current_band_y += band_pixels
    end
#
# Current band now contains timing marks. So back off by two bands and trim the image. (Backing off by one sometimes cuts off the slightest 
# sliver of the timing marks and messes things up.
#
    current_band_y -= band_pixels * 2
    side_crop :top, :row, imageId, current_band_y
    @upstream.ann_offset(0, current_band_y)
    d_write_image imageId
  end

  def open_ballot_image_old imageId, filename, dpi
    self.target_dpi = dpi
    open_image imageId, filename, dpi

# Remove black snudge edge along top, if any
    after_black = find_last_row :black, imageId
    if after_black > 0
      @upstream.ann_offset(0, after_black)
      side_crop :top, :row, imageId, after_black+1
    end
    
# Now slice off the wide white top margin
    nonwhite = find_last_row :white, imageId
    adjusted_nonwhite = nonwhite-i2p(TopwhiteMarginOffset)
    crop_top_rows imageId, adjusted_nonwhite
    
    @upstream.ann_offset(0, adjusted_nonwhite)
    d_write_image imageId
  end
  
 
#
# Locate and compute the offset and angle of the (timing or registration) marks in the indicated part
# of the image.
#
# <tt>side</tt>:: What side of the image are the marks. <tt>:top, :left, or :right</tt>
# <tt>image</tt>:: The <tt>imageID</tt> of the image to analyze
# <tt>extent</tt>:: The extent, in inches, from the designated edge
# Returns:
    LocateMarks = Struct.new("LocateMarks", :firstmark, :lastmark, :angle)
# <tt>firstmark</tt>:: the offset, in pixels, where the first mark is found. The origin.
# <tt>lastmark</tt>:: the offset, in pixels, where the last mark is found
# <tt> angle</tt>:: the angle, in degrees, corresponding to the detected skew
#

  def locate_marks side, image, extent
    d_write_image image
#
# Look at a rectangle each of the ends of the bands. Rect1 is one end, Rect2 is the other end.
#
    rect1segments = Array.new
    if side == :top
      detect_marks image, 0, 0, i2p(EndRectSize), i2p(extent), :left, 
                   SideBandThresh, :columns, i2p(MinMarkHeight), :rect1, rect1segments, "top" 
    elsif side == :left
      detect_marks image, 0, 0, i2p(extent), i2p(EndRectSize), :up,
                   ThreshLeft1, :rows, i2p(MinMarkWidth), :rect1, rect1segments, "left" 
    elsif side == :right
      detect_marks image, columns(image) - i2p(extent), 0, i2p(extent), i2p(EndRectSize), :up, 
                   ThreshRight1, :rows, i2p(MinMarkWidth), :rect1, rect1segments, "right" 
    end
    return LocateMarks.new(BPoint.nil, BPoint.nil, 0.0) if rect1segments.length != 1

    rect2segments = Array.new
    if side == :top
      detect_marks image, columns(image) - i2p(EndRectSize), 0,  i2p(EndRectSize), i2p(EndRectSize), :left, 
                   SideBandThresh, :columns, i2p(MinMarkHeight), :rect2, rect2segments, "top" 
    elsif side == :left
      detect_marks image, 0, rows(image) - i2p(EndRectSize), i2p(extent), i2p(EndRectSize), :up, 
                   ThreshLeft2, :rows, i2p(MinMarkWidth), :rect2, rect2segments, "left" 
    elsif side == :right
      detect_marks image, columns(image) - i2p(extent), rows(image) - i2p(EndRectSize), i2p(extent), i2p(EndRectSize), :up, 
                   ThreshRight2, :rows, i2p(MinMarkWidth), :rect2, rect2segments, "right" 
    end
    return LocateMarks.new(BPoint.nil, BPoint.nil, 0.0) if rect2segments.length == 0
#
# Now project the timing marks to the top (or side) to figure out the offsets in the other direction.
#
    rect3segments = Array.new
    if side == :top
      detect_marks image, 0, 0, columns(image), i2p(extent), :up, 
                   ThreshTop3, :rows, i2p(MinMarkWidth), :rect3, rect3segments, "top"       
    elsif side == :left
      detect_marks image, 0, 0, i2p(extent), rows(image), :left, 
                   ThreshLeft3, :columns, i2p(MinMarkHeight), :rect3, rect3segments, "left"       
    elsif side == :right
      detect_marks image, columns(image) - i2p(extent), 0, i2p(extent), rows(image), :left, 
                   LongSideThresh, :columns, i2p(MinMarkHeight), :rect3, rect3segments, "right"       
    end
    d_write_image :rect3
    
    if side == :top
  # Compute the midpoint of the first timing mark
      origin = BPoint.new(rect3segments[0][0], rect1segments[0][0])
      origin_prime = BPoint.new(rect3segments[0][0], rect1segments[0][1])
      firstmarkmidpoint = BLine.new(origin, origin_prime).mid
      
  # Compute the midpoint of the last timing mark
      terminal = BPoint.new(rect3segments[-1][0], rect2segments[0][0])
      terminal_prime = BPoint.new(rect3segments[-1][0], rect2segments[0][1])
      secondmarkmidpoint = BLine.new(terminal, terminal_prime).mid
      rotation_angle = BPoint.angle(firstmarkmidpoint, secondmarkmidpoint)

# Have a headache yet? Detailed arithmetic is different (signs etc.) depending on side
 
    elsif side == :left 

  # Compute the midpoint of the first timing mark
      origin = BPoint.new(rect1segments[0][0], rect3segments[0][0])
      origin_prime = BPoint.new(rect1segments[0][1], rect3segments[0][0])
      firstmarkmidpoint = BLine.new(origin, origin_prime).mid
      
  # Compute the midpoint of the last timing mark
      terminal = BPoint.new(rect2segments[0][0], rect3segments[-1][0])
      terminal_prime = BPoint.new(rect2segments[0][1], rect3segments[-1][0])
      secondmarkmidpoint = BLine.new(terminal, terminal_prime).mid
      rotation_angle = (BPoint.angle(firstmarkmidpoint, secondmarkmidpoint) - 90.0).modulo 90.0

    elsif side == :right

  # Compute the midpoint of the first timing mark
      origin = BPoint.new(rect1segments[-1][0], rect3segments[0][0])
      origin_prime = BPoint.new(rect1segments[-1][1], rect3segments[0][0])
      firstmarkmidpoint = BLine.new(origin, origin_prime).mid
      
  # Compute the midpoint of the last timing mark
      terminal = BPoint.new(rect2segments[-1][0], rect3segments[-1][0])
      terminal_prime = BPoint.new(rect2segments[-1][1], rect3segments[-1][0])
      secondmarkmidpoint = BLine.new(terminal, terminal_prime).mid
      rotation_angle = (BPoint.angle(firstmarkmidpoint, secondmarkmidpoint) - 90.0).modulo 90.0
#
# unlike the left and top, on the right the origin of the first mark is not the origin of the page. We need 
# to compensate for the distance between the page's actual origin and where the right marks are, by using the
# known distance between the timing marks along the top and the space between then and how many there are.
#
      origin.x = origin.x + columns(image) - i2p(extent)
      terminal.x = terminal.x + columns(image) - i2p(extent)
    end
    return LocateMarks.new(origin, terminal, rotation_angle)
  end
  
#
# implements the recipe for detecting timing marks in one of the three edges of a ballot.
# <tt>inimage</tt>:: Imageid of image we are working with
# <tt>x, y, width, height<tt>:: rectange corresponding to subimage containing the timing marks
# <tt>direction</tt>::  :up or :left, to show what direction we are projecting the band for discovery
# <tt>threshold</tt>::  number between 0 and 100 for the threshold to apply to best make the bands visible
# <tt>rowcol</tt>::  :rows or :columns to control in what direction we are looking for the dashes
# <tt>minsize</tt>::  smallest length of black pixels that would be considered a mark
# <tt>outimage</tt>::  Imageid of subimage that we are working with
# <tt>segments</tt>:: Array that will receive the start and end of detected segments
# <tt>comment</tt>:: String used in debug output for this call
#
  def detect_marks inimage, x, y, width, height, direction, threshold, rowcol, minsize, outimage, segments, comment 
    copy_subimage inimage, x, y, width, height, outimage
    d_write_image outimage, comment+"_subimage"
    project_image outimage, direction
    d_write_image outimage, comment+"_projected"
    threshold outimage, threshold
    d_write_image outimage, comment+"_thresholded"
    find_black_segments rowcol, outimage, segments, minsize
  end
end


#
# Represent a Point 
#
  class BPoint
    attr_accessor :x, :y

#
# Class method: angle. Compute angle between two points
# <tt>p1</tt>:: First point
# <tt>p2</tt>:: Second point
# 
# Step by step calculation is to make sure it's in Float, and also to allow intermediate debugging.
# I am sure there's a better way.
    def self.angle p1, p2
      tan = (0.0 + p2.y-p1.y)/(p2.x-p1.x)
      atan = Math::atan(tan)
      angle = self.rad_to_deg(atan)
#      puts "angle between: #{p1} and #{p2} is #{angle}"
      return angle
    end
    
    def self.rad_to_deg rad
      rad * 360.0 / (2.0 * Math::PI)
    end
    
    def self.deg_to_rad deg
      (deg * Math::PI) / 180.0
    end
    
    def self.nil
      BPoint.new(nil, nil)
    end

    def initialize x, y
      @x, @y = x, y
    end
    
    def ==(other)
      return @x == other.x && @y == other.y
    end
    
    def distance other
      raise "Must call Point#distance with another point" unless other.class == BPoint
      Math.sqrt((other.x - @x)**2 + (other.y-@y)**2)
    end
    
    def to_s
      "point x=#{@x}, y=#{@y}"
    end
 #
 # unary minus
 #
    def -@
      BPoint.new(-@x, -@y)
    end
    
    def offset(opoint)
      BPoint.new(@x + opoint.x, @y + opoint.y)
    end
 
#
# Rotate this point by the indicated angle
#
# <tt>theta</tt>::  angle to rotate, in radians
#
    def rotate(theta)
      new_x = Math::cos(theta) * @x - Math::sin(theta) * @y 
      new_y = Math::sin(theta) * @x + Math::cos(theta) * @y
      BPoint.new(new_x, new_y)
    end
    
  end
  
# 
# Represent a straight line, defined by two points
#
  class BLine
    attr_accessor :p1, :p2

    def initialize p1, p2
      raise "invalid initializer for a line" unless p1.class == BPoint && p2.class == BPoint
      @p1 = p1
      @p2 = p2
    end

#
# Return a Point which is the midpoint of the defined line
#    
    def mid
      mid_of_x = (@p2.x - @p1.x) / 2 + @p1.x
      mid_of_y = (@p2.y - @p1.y) / 2 + @p1.y
      BPoint.new(mid_of_x, mid_of_y)
    end
  end

