=begin
  * Name: Ballot-analyzer
  * Description: Analyze voting ballots
  * Author: Pito Salas
  * Copyright: (c) R. Pito Salas and Associates, Inc.
  * Date: January 2009
  * License: GPL

  This file is part of GovSDK.

  GovSDK is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  GovSDK is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with GovSDK.  If not, see <http://www.gnu.org/licenses/>.

  require "ruby-debug"
  Debugger.settings[:autolist] = 1 # list nearby lines on stop
  Debugger.settings[:autoeval] = 1
  Debugger.start
=end

require 'rubygems'
require 'RMagick'
include Magick

class IaDsl
  
# Some convenient constants
  White = QuantumRange   # QuantumRange is white when it occurs as the intensity value in a B&W image
  Black = 0
  
  def initialize
    @var_table = Hash.new
    @profiling = false
    @tracing = false
    @prof_data = Hash.new
  end

#
# Turn on and off various tracing, logging and profiling commands
#
  def diagnostics command
    if command == :profile
      puts "++ Profiling Started\n\n"
      @profiling = true
    elsif command == :end
      generate_profiling_report
      @profiling = false
      @tracing = false
    elsif command == :generate
      generate_profiling_report if @profiling
    elsif command == :trace
      @tracing = true
    end
  end

#
# Print variable and internal status
#   
  def print var_name
    v = @var_table[var_name]
    if v.class == Array
      puts "Array: #{v.length}: #{@var_table[var_name].inspect}"
    elsif v.class == Fixnum
      puts "Integer: #{v}"
    elsif v.nil?
      puts "nil"
    end
  end
  
#
# File handling. Open a single image file. Optionally ask for it to be converted to a certain DPI.
#  
  def open_image id, filename, target_dpi=nil
    m_begin "open_image"
# Read in the file as an imagelist. The new image will be in the first position of the array.
    img = ImageList.new(filename)
    img = img[0]
    put_image(id, img)
    if !target_dpi.nil?
      img = resample id, target_dpi
    end
    m_end "open_image"
  end

#
# Save a single image file. If second param is not supplied then we will use the image id (id) as the name of the file too. 
# That's just a handy short hand to make things easier when debugging.
#  
  def write_image id, filename=nil
    m_begin "write_image"
    filename = id.to_s+".gif" if filename.nil?
    get_image(id).write(filename)
    m_end "write_image"
  end
  
#
# Get height and width of the image in pixels
#
  def rows id
    get_image(id).rows
  end
  
  def columns id
    get_image(id).columns
  end
  
# 
# Get info about an image
#
  def image_dpi id
    image = get_image(id)
    raise "Surprising non-symetrical dpi" if image.x_resolution != image.y_resolution 
    [image.x_resolution, image.y_resolution]  
  end

  
#
# Image Processing
#  
#
# Deskew image
#
  def deskew image
    m_begin "deskew"
    set_variable(image, get_image(image).deskew)
    m_end "deskew"
  end

#
# Despeckle, which is to say, remove noise
#
  def despeckle image
    m_begin "despeckle"
    set_variable(image, get_image(image).despeckle)
    m_end "despeckle"
  end
  
#
# Cleanup lines by magic
#
  def cleanup image
    m_begin "cleanup"
    img = get_image(image)
    img = img.gaussian_blur(8)
    img = img.threshold((QuantumRange * 0.999).to_int)
    img = img.gaussian_blur(14)
    img = img.threshold(0)
    m_end "cleanup"
    set_variable(image, img)
  end
  
#
# Morphological "close" operation
#
  def morphological_close image
    m_begin "morphological_close"
    morphological_dilate image
    morphological_erode image
    m_end "morphological_close"
  end
  
#
# Morpological "open" operation
#
   def morphological_open image, iteration=1
     m_begin "morphological_open"
     iteration.times do
       morphological_erode image
       morphological_dilate image
     end
     m_end "morphological_open"
   end

#
# Morpological "dilate" operation
#
   def morphological_dilate image
     img = get_image(image)
     img = img.convolve(3, [1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
     img = img.bilevel_channel(QuantumRange * 0.0)
     put_image(image, img)
   end
   
#
# Morpological "dilate" operation
#
  def morphological_erode image
    img = get_image(image)
    img = img.convolve(3, [1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
    img = img.bilevel_channel(QuantumRange * 0.99)
    put_image(image, img)
  end

  
# 
# Turn a color image to B&W
#
  def binarize id
    m_begin "binarize"
    put_image(id, get_image(id).bilevel_channel(QuantumRange/2))
#   put_image(id, @var_table[id].quantize(2, GRAYColorspace, NoDitherMethod) )
    m_end "binarize"
  end
  
#
# Resample, change dpi of an image
# 
  def resample inimage, dpi, outimage=nil
    m_begin "resample"
    img = get_image(inimage)
    old_dpi = (image_dpi inimage)[0]
    if old_dpi != dpi then
      if false
        out = img.resample(dpi)
      elsif 
        old_dpi = (image_dpi inimage)[0]
        ratio = dpi / old_dpi
        out = img.sample(ratio)
        out.density = "#{dpi}x#{dpi}"
      end
    else
      out = img
    end
    outimage = inimage if outimage.nil?
    put_image(outimage, out)
    m_end "resample"
  end
  

  
#
# Display an image on the X terminal
# 
  def display id
    get_image(id).display
  end
  
#
# Geometrical Operations
#

# 
# Rotate an image
#
  def rotate image, angle, outimage=nil
    m_begin "rotate"
    img = get_image(image)
    if false
      rotated = img.rotate(angle)
    else
#
# from newsgroup: The alternative way to rotate is to use -filter point +distort SRT {angle} +repage
#
      rotated = img.resize(img.columns, img.rows, PointFilter)
      rotated = img.distort(ScaleRotateTranslateDistortion, [angle])
    end
    outimage = image if outimage.nil?
    put_image(outimage, rotated)
    m_end "rotate"
  end


#
# Crop the image so that 'rows' rows are deleted from the top
#
  def  crop_top_rows image, starting_row, outimage=nil
    raise "number expected" unless starting_row.class == Fixnum
    m_begin "crop_top_rows"
    img = get_image(image)
    cropped = img.excerpt(0, starting_row, img.columns, img.rows-starting_row)
    outimage = image if outimage.nil?
    put_image(outimage, cropped)
    m_end "crop_top_rows"
  end
  
#
# Crop the image so that ...
# 
# Underlying ImageMagick call is:
#     img.crop(x, y, width, height) ->  image
#
  def  side_crop side, rowcol, image, starting, outimage=nil
    m_begin "side_crop"
    raise "number expected" unless starting.class == Fixnum
    raise "side wrong: #{side}" unless [:top, :bottom, :left, :right].member? side
    raise "rowcol wrong: #{rowcol}" unless [:row, :column].member? rowcol
    img = get_image(image)
    case [side, rowcol]
    when [:left, :column]
      cropped = img.excerpt(starting, 0, img.columns-starting, img.rows)
    when [:right, :column]
      cropped = img.excerpt(0, 0, img.columns-starting, img.rows)
    when [:top, :row]
      cropped = img.excerpt(0, starting, img.columns, img.rows-starting)
    when [:bottom, :row]
      cropped = img.excerpt(0, 0, img.columns, img.rows-starting)
    else
      raise "invalid rowcol and side combination"
    end
    outimage = image if outimage.nil?
    put_image(outimage, cropped)
    m_end "side_crop"
  end

#
# Copy a rectangle of pixels from one image into a new image
#  
  def copy_subimage inimage_id, x, y, width, height, outimage_id
    m_begin "copy_subimage"
    img = get_image(inimage_id)
    outimg = img.excerpt(x, y, width, height)
    outimage_id = inimage_id if outimage_id.nil?
    put_image(outimage_id, outimg)
    m_end "copy_subimage"
  end
    
# 
# Take a vertical column out of this image and return it as another image
#
  def slice_column inimage, colbeg, colend, outimage
    m_begin "slice_column"
    img = get_image(inimage)
    slice = img.excerpt(colbeg, 0, colend-colbeg, img.rows)
    put_image(outimage, slice)
    m_end "slice_column"
  end
  
#
# take a horizontal row out of this image and return it as another image
#
  def slice_row inimage, rowbeg, rowend, outimage
    m_begin "slice_row"
    img = get_image(inimage)
    slice = img.excerpt(0, rowbeg, img.columns, rowend-rowbeg)
    put_image(outimage, slice)
    m_end "slice_row"
  end
  
#
# Given an single row or column of pixels, find segments of it which are black and return the start, 
# end of each segment in a 2 dimensional array. Any segments fewer than 'minsize' pixels are not recorded.
#
  def find_black_segments rowcol, inimage, outarray, minsize=nil
    m_begin "find_black_segments"
    img = get_image(inimage)
    raise "invalid rowcol" unless [:columns, :rows].member? rowcol
    raise "invalid image" unless (img.columns == 1 && rowcol == :columns) || (img.rows == 1 && rowcol == :rows)
    raise "invalid outarray" unless outarray == []
    if rowcol == :rows
      scanline = img.export_pixels(0, 0, img.columns, 1, map="I")
    elsif rowcol == :columns
      scanline = img.export_pixels(0, 0, 1, img.rows, map="I")
    end
    zonecolor = White
    segstart = 0
    scanline.each_index do |i|
      pix = scanline[i]
      if pix != zonecolor && zonecolor == White
        segstart = i
        zonecolor = pix
      elsif pix != zonecolor && zonecolor == Black
        outarray << [segstart, i] unless !minsize.nil? && (i - segstart) < minsize
        zonecolor = pix
      end
    end
  # If we reach the end of the row and it's still black, we need to still complete the final segment
    if zonecolor == Black then
       outarray << [segstart, scanline.length-1] unless !minsize.nil? && (scanline.length-1 - segstart) < minsize
    end       
    m_end "find_black_segments"
  end

  def find_w2b_transitions inimage, outarray
    raise "find_w2b_transitions is depracated..."
    m_begin "find_w2b_transitions"
    img = get_image(inimage)
    result = Array.new
    pixels = img.get_pixels(0, 0, 1, img.rows)
    zonecolor = "white"
    pixels.each_index do |index|
      p = pixels[index]
      colr = p.to_color
      if colr != zonecolor && colr == "black"
        result << index
      end
      zonecolor = colr
    end
    @var_table[outarray] = result
    m_end "find_w2b_transitions"
  end        

#
# Use imagemagick to find 'similar' regions
#  
  def find_similar_regions image, target, points
    m_begin "find_similar_regions"
    res_points = Array.new
    image_being_searched = get_image(image)
    goal_image = get_image(target)
    curX, curY = 0, 0
    while res = image_being_searched.find_similar_region(goal_image, curX, curY) do
      curX, curY = res
      res_points << res
      curX = curX + 1
      curY = curY + 1
    end
    set_variable(points, res_points)
    m_end "find_similar_regions"
  end
  
# 
# Primitive scoring of a mark. 
#
  def inspect_checkbox image, xpos, ypos, width, height
    m_begin_noprint "inspect_checkbox"
    img = get_image(image)
    checkbox_pixels = img.excerpt(xpos, ypos, width, height)
    shrink_to_one = checkbox_pixels.scale(1,1)
    score = shrink_to_one.get_pixels(0,0,1,1)[0].red
    m_end_noprint "inspect_checkbox"
    score
  end
  
#
# Methods to help process various arrays of coordinates in various handy ways
#

#
# Convert an array of segment start and stops (e.g. [ [1, 10], [12, 15], ... ]) to 
# an array of midpoints of each segment (e.g. [ 5, 14, ... ])
#
  def convert_segs_to_mids segments, midpoints
    raise "invalid arrays" if segments.class != Array || midpoints.class != Array
    segments.each do |seg|
      seg_top = seg[1]
      seg_bottom = seg[0]
      midpoint = (seg_top - seg_bottom) / 2 + seg_bottom
      midpoints << midpoint
    end
  end
  
#
# Convert an array of absolute x,y point coordinates so that the next point's coordinates are deltas from the
# previous one.
#
  def relativize_points points, rel_points
    m_begin "relativize_points"
    raise "invalid argument" unless points.class == Array && rel_points.class == Array
    lastx, lasty = 0, 0
    points.each do
      |x, y|
        rel_points << [x-lastx, y-lasty]
        lastx = x
        lasty = y
    end
    m_end "relativize_points"
  end
  
#
# Start scanning at 0,0 of a black and white image, and determine the first row that constains a single nonwhite pixel.
# img.export_pixels with a map parameter of "I" returns intensities of each pixel as an integer. 
#
  def find_first_nonwhite_row image_being_searched
    m_begin "find_first_nonwhite_row"
    img = get_image(image)
    rows = img.rows
    cols = img.columns
    rows.times do |row|
      scanline = img.export_pixels(0, row, cols, 1, map="I")
      scanline.each {|x| return row if x != White}
    end
    m_end "find_first_nonwhite_row"
    nil
  end
  
  
#
# Starting at row 0 of the input image, look at each row to see if it is (almost) white. If it's not, then return
# the row number of the one before.  We use a different technique here: we scale all the pixels of the row into a single pixel
# which will give that pixel a color which reflects the colors of all the pixels.
#
  def find_last_white_row image
    raise "deprecated"
    m_begin "find_last_white_row"
    img = get_image(image)
    img.rows.times do |row|
      row_excerpt = img.excerpt(0, row, img.columns, 1)
      row_dot = row_excerpt.scale(1, 1)
      color = row_dot.get_pixels(0,0,1,1)[0].red
      return row-1 if color <= White * 0.75
    end
    m_end "find_last_white_row"
    nil
  end

#
# Just like find_last_white_row, but for columns. Scan an image from left to right, and return the index of the 
# last column which is almost pure white. # We scale all the pixels of the row (column) into a single pixel
# which will give that pixel a color which reflects the colors of all the pixels.
# 
  def find_last_white_column inimage
    raise "deprecated"
    m_begin "find_last_white_column"
    img = get_image(image)
    img.columns.times do |col|
      col_excerpt = img.excerpt(col, 0, 1, img.rows)
      col_dot = col_excerpt.scale(1, 1)
      color = row_dot.get_pixels(0,0,1,1)[0].red
      return row-1 if color <= White * 0.75
    end
    m_end "find_last_white_column"
    nil
  end
  

#
# Just like find_last_row, but for columns. Scan an image from left to right, and return the index of the 
# last column which is almost pure white (pure black). We scale all the pixels of the column into a single pixel
# which will give that pixel a color which reflects the colors of all the pixels.
#
  def find_last_column color, inimage
    m_begin "find_last_column"
    img = get_image(inimage)
    img.columns.times do |col|
      col_excerpt = img.excerpt(col, 0, 1, img.rows)
      col_dot = col_excerpt.scale(1, 1)
      pixelcolor = col_dot.get_pixels(0,0,1,1)[0].red
      if color == :white
        return col-1 if pixelcolor <= White * 0.75
      elsif color == :black
        return col-1 if pixelcolor >= White * 0.75
      else
        raise "invalid color symbol in find_last_color"
      end
    end
    nil
  ensure
    m_end "find_last_column"
  end

#
# Just like find_last_column, but for rows. Scan an image from top to bottom (bottom to top), and return the index of the 
# last row which is almost pure white (pure black). We scale all the pixels of the row into a single pixel
# which will give that pixel a color which reflects the colors of all the pixels.
#
  def find_last_row color, inimage, direction= :top_to_bottom
    m_begin "find_last_row"
    img = get_image(inimage)
    img.rows.times do |row|
      if direction == :top_to_bottom 
        row_excerpt = img.excerpt(0, row, img.columns, 1)
      elsif direction == :bottom_to_top
        row_excerpt = img.excerpt(0, img.rows-row, img.columns, 1)
      else
        raise "invalid direction symbol in find_last_row"
      end
      row_dot = row_excerpt.scale(1, 1)
      pixelcolor = row_dot.get_pixels(0,0,1,1)[0].red
      if color == :white
        return row-1 if pixelcolor <= White * 0.75
      elsif color == :black
        return row-1 if pixelcolor >= White * 0.75
      else
        raise "invalid color symbol in find_last_row"
      end     
    end
    nil
  ensure
    m_end "find_last_row"
  end
  
#
# Don't use! This 'leaks' out the image data structure from Imagick.
#
  def get_image(id)
    val = @var_table[id]
    raise "not an image" if val.nil?
    val
  end
  
    
#
# Internal utility methods, that don't use var_table as the way to get info in and out
#
  private
  
#
# true if all the pixels in 'row' are white
#
  def row_all_white?(image, row)
    pixels = image.get_pixels(0, row, image.columns, 1)
    i = 0
    pixels.each do |p|
      return false unless p.to_color == "white"
      i += 1
    end
    return true
  end

#
# Profiling helpers
#
   class ProfInfo
     attr_accessor :calls_count, :timer_start, :cumulative_time

     def initialize
       @calls_count = 0
       @cumulative_time = 0
     end
   end

   def profiling?
     @profiling
   end

   def m_begin name
     puts ">> Entering #{name}" if @tracing
     m_begin_noprint name
   end
   
   def m_begin_noprint name
     return unless profiling?
     @prof_data[name] = ProfInfo.new if @prof_data[name] == nil
     prof = @prof_data[name]
     prof.calls_count += 1
     prof.timer_start = Time.now
   end
   
   def m_end name
     puts "<< Leaving #{name}" if @tracing
     m_end_noprint name
   end
     
   def m_end_noprint name
     return unless profiling?
     prof = @prof_data[name]
     raise "m_end without corresponding m_begin: #{name}" if prof.nil?
     prof.cumulative_time += Time.now - prof.timer_start
   end
   
   def generate_profiling_report
     return unless profiling?
     puts "\n+++ Profiling:"
     @prof_data.each do |key, value|
       printf "%25s   (%dx)   avg: %1.3f sec\n", key, value.calls_count, value.cumulative_time/value.calls_count
     end
   end
   
   def m_trace arg
     puts arg if @tracing
   end
   
   def d_write_image id, filename=nil
     write_image id, filename if @tracing
   end
       
#
# Access helpers
#
  def get_fixnum(id)
    return id if id.class == Fixnum

    val = @var_table[id]
    raise "not a fixnum" unless val.class == Fixnum
    val
  end
  
  def put_image(id, img)
    set_variable(id, img)
  end
  
  def set_variable(id, val)
    old_value = @var_table[id]
    if !@var_table[id].nil? && @var_table[id].class == Image && old_value != val
      old_value.destroy!
    end
    @var_table[id] = val
  end

end
