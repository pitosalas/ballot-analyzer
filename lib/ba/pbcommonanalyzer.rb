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

class PbCommonAnalyzer < IaDsl
  
  EndRectSize = 1.0   # Size, in inches, of the rectangle that is taken off a band to analyze skew
  MinMarkExtent = 0.75/16   # Size, in inches, of the shortest band of black that will be considered a timing mark

  attr_accessor :target_dpi

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
# Utility function to convert from pixels to inches based on the dpi
#
#<tt>pixels</tt>::  dimension in pixels
# Returns dimension in inches
#
  def p2i(pixels)
    (pixels * @target_dpi)
  end
  
#
# Locate and compute the offset and angle of the (timing or registration) marks in the indicated part
# of the image.
#
# <tt>side</tt>:: What side of the image are the marks. <tt>:top, :left, or :right</tt>
# <tt>image</tt>:: The <tt>imageID</tt> of the image to analyze
# <tt>offset</tt>:: The offset, in inches, from the designated edge
# Returns:
# <tt> offset</tt>:: the offset, in inches, where the first mark is found. The origin.
# <tt> angle</tt>:: the angle, in degrees, corresponding to the detected skew
#
  def locate_marks side, image, offset
    raise "invalid argument" unless side == :top
#
# Look at a rectangle each of the ends of the bands to figure out the skew and offset. 
#
    copy_subimage image, 0, 0, i2p(EndRectSize), i2p(EndRectSize), :rect1
    copy_subimage image, columns(image) - i2p(EndRectSize), 0, i2p(EndRectSize), i2p(EndRectSize), :rect2
    project_image :rect1, :left, :rect1projected
    project_image :rect2, :left, :rect2projected
    threshold :rect1projected, 40.0
    threshold :rect2projected, 40.0      
    d_write_image :rect1projected
    d_write_image :rect2projected
    rect1segments = Array.new
    rect2segments = Array.new
    find_black_segments :columns, :rect1projected, rect1segments, i2p(MinMarkExtent)
    find_black_segments :columns, :rect2projected, rect2segments, i2p(MinMarkExtent)
    [0,0]
  end

  
end
