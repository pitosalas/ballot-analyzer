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

=end
#
# Class is passed into various other methods, supplying a strategy for retruning information upstream, 
# to calling clients and routines.
#
# logging: messages for a log window
# upstreaming: specific status commands in a fixed format to control calling software
# annotation: status as communicated visually 
# 
class UpstreamReporter
  
#
# initialize with the two basic states
#
# <tt>enable_up</tt>:: enable upstreaming
# <tt>enable_log</tt>:: enable logging
# <tt>enable_annotate</tt>::  enable annotation
  def initialize(enable_up, enable_log, enable_ann)
    @upstreaming = enable_up
    @logging = enable_log
    @ann_enabled = enable_ann
  end
  
#
# submit "info" message to log
#
# <tt>str</tt>::  text for log
#
  def info str
    puts "log: #{str}" if @logging
  end

#
# submit upstream command string
#
# <tt>str</tt>:: upstream command
#
  def stream str
    puts str if @upstreaming
  end

#
# Begin annotation of this image file. Annotation takes an initial image file, and draws boxes and stuff
# on it. The annotations are supplied in subsequent calls and pertain to the current annotation image
#
# <tt>imagefile</tt>::  Filename containing image to be annotated
# <tt>name</tt>:: 'display name' used for other messages about this image
#
  def ann_begin(imagefile, name)
    @ann_name = name
  end

#
# Offset from image's actual origin that will pertain to the various annotation calls following.
#
# <tt>x</tt>::  x position
# <tt>y</tt>::  y position (duh)
#
  def ann_offset(x, y)
    @ann_x_offset = x
    @ann_y_offset = y
  end
  
#
# Annotate with a rectangle.
#
# <tt>top</tt>::  top coordinate (in pixels)
# <tt>left</tt>::  left coordinate (in pixels)
# <tt>width</tt>::  height (in pixels)
# <tt>height</tt>::  width (in pixels)
#
  def ann_rect(top, left, width, height)
  end

#
# Complete a single annotated image. Next call needs to be "ann_begin"
#
  def ann_done
    @ann_name = nil
  end

end
