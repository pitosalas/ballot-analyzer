include IaDsl

class PremierBallot
  
  attr_reader :raw_barcode, :raw_marked_votes
  
# There are a ton of little parameters that can be adjusted to control the details of the analysis
# of a ballot. They are determined empirically by trial and error. Once we figure them out there's 
# no reason to ever change them unless the ballot layouts change.

# Geometric constants, in inches.
  Timing_mark_minwidth = 0.1333 # 40
  Timing_mark_typheight = 0.06 # 18

  Row1st_top_timing_band = 0.0 # 0
  Rowlast_top_timing_band = 0.15 # 0.1 # 30
  Scanline_top_timing_mark = 1/16.0 # 0.033 # 10 # 8

  Col1st_left_timing_band = 0.0 # 0
  Collast_left_timing_band = 3/8.0 # 0.4 # 0.333 # 100
  Colkey_left_timing_band = 3/32.0 # 0.15 # 30 # 20
  Min_height_left_timing_mark = 0.0625 # 10 
  Minimum_width_left_timing_mark = 0.1333 # 40 
  Offset_from_left_timing_mark_top = 0.01666 # 5
  Offset_from_left_timing_band_edge = 3/8.0 # 0.333 # 100
  
# Voting Oval dimensions
  Vote_oval_width = 0.12 # 36
  Vote_oval_height = 0.08 # 24
  
# Iteration counts for morphological operations
  Morph_iter_left_timing_band = 3
  Morph_iter_top_timing_band = 3
  Morph_iter_barcode = 4

# How skewed does the image have to be to require a rotate (which is very expensive)
  Min_degree_requiring_deskew = 0.15
    
# Default DPI that image is converted to before processing
  Target_DPI_default = 300
  
# Sanity Checks
  Top_timings_mark_count = 34
  Left_timing_marks_count = 53
  
  def initialize t_dpi=Target_DPI_default
    @target_dpi = t_dpi
  end
    
#
# Utility function that converts a geometric parameter specified in inches into what it would be in pixels
#
  def g(inches)
    (inches * @target_dpi).to_i
  end
  
  def diags setting
    IaDsl::diagnostics setting
  end
  
  def file_to_process= fname
    reset_per_ballot_state
    @filename = fname
  end
  
  def reset_per_ballot_state
    @raw_barcode = []
    @raw_marked_votes = []
  end
  
  def file_to_process
    @filename
  end

  def process_one
    m_trace "Premier Ballot."
    m_trace "  Processing #{@filename}"
    m_trace "  Target DPI=#{@target_dpi}"
    open_image :ballot, @filename, @target_dpi
    binarize :ballot
    d_write_image :ballot

  # Remove black edge along top, if any
    after_black = find_last_row :black, :ballot
    if after_black > 0
      side_crop :top, :row, :ballot, after_black+1
    end

  # Remove black edge along left, if any
    after_black = find_last_column :black, :ballot
    if after_black > 0
      side_crop :left, :column, :ballot, after_black+1
    end
    
  # Remove black edge along bottom, if any
    after_black = find_last_row :black, :ballot, :bottom_to_top
    if after_black > 0
      side_crop :bottom, :row, :ballot, after_black+1
    end

  # Now slice off the wide white top margin
    nonwhite = find_last_row :white, :ballot
    crop_top_rows :ballot, nonwhite, :cropped
    d_write_image :cropped

debugger

  # Slice away the approximate area of the timing marks along the left. Then clean them up with a morphological_open
    slice_column :cropped, g(Col1st_left_timing_band), g(Collast_left_timing_band), :left_timing_marks
    morphological_open :left_timing_marks, Morph_iter_left_timing_band
    d_write_image :left_timing_marks

  # Take a one pixel slice along the left
    slice_column :left_timing_marks, g(Colkey_left_timing_band), g(Colkey_left_timing_band)+1, :left_col
    row_timing_marks = []
    find_black_segments :columns, :left_col, row_timing_marks, g(Min_height_left_timing_mark)
    d_write_image :left_col
    
  # Sometimes there's a black bleed at the bottom of the page that can be confused with a timing mark. Detect and
  # remove it before checking that we have the correct number. So, if the second parameter (which is the bottom)
  # of the last timing mark -- 'row_timing_marks[-1][1]' is equal to the total number of rows in the image, then
  # delete that timing mark.
  
    if row_timing_marks[-1][1] == rows(:left_col)-1
      row_timing_marks.delete_at(-1)
    end
    
  # Sanity check
    if row_timing_marks.length != Left_timing_marks_count
      raise "Analysis failure on left timing marks: expected #{Left_timing_marks_count}, but got #{row_timing_marks.length}"
    end
  
  # Examine first timing mark
    pos_1st_mark = row_timing_marks[0]
    y_top = pos_1st_mark[0]
    copy_subimage :left_timing_marks, 0, y_top + g(Offset_from_left_timing_mark_top), g(Offset_from_left_timing_band_edge), 1, :img_1st_mark
    d_write_image :img_1st_mark
    black_segs = []
    find_black_segments :rows, :img_1st_mark, black_segs, g(Minimum_width_left_timing_mark)
    x_top = black_segs[0][1]
  
  # Examine last timing mark
    pos_last_mark = row_timing_marks[-1]
    y_bottom = pos_last_mark[0]
    copy_subimage :left_timing_marks, 0, y_bottom+g(Offset_from_left_timing_mark_top), g(Offset_from_left_timing_band_edge), 1, :img_last_mark
    d_write_image :img_last_mark
    black_segs = []
    find_black_segments :rows, :img_last_mark, black_segs, g(Minimum_width_left_timing_mark)
    x_bottom = black_segs[0][1]

    m_trace "[#{x_top},#{y_top}] ....[#{x_bottom},#{y_bottom}]"

  # Now see if deksewing is necessary by computing the relative positions
    tangent = (x_bottom.to_f - x_top.to_f) / (y_bottom.to_f - y_top.to_f)
    atan = Math::atan2( x_bottom - x_top, y_bottom - y_top) * 360.0 / (2.0 * Math::PI)
    m_trace "[rotate degree = #{atan}]"
    if atan.abs > Min_degree_requiring_deskew
      rotate :cropped, atan
      d_write_image :cropped
      puts "[rotate degree = #{atan}]"
    end
  
  # Grab the rows corresponding to the top timing marks and clean it up
    slice_row :cropped, g(Row1st_top_timing_band), g(Rowlast_top_timing_band), :top_timing_band
    morphological_open :top_timing_band, Morph_iter_top_timing_band
    d_write_image :top_timing_band

  # take a one pixel slice along the top to find the timing marks along the top. Clean it up to get rid of noise, and 
  # then look at intervals to locate the black segments which are then the timing marks.
    slice_row :top_timing_band, g(Scanline_top_timing_mark), g(Scanline_top_timing_mark)+1, :top_timing_row
    column_timing_marks = []
    find_black_segments :rows, :top_timing_row, column_timing_marks, g(Timing_mark_minwidth)
    d_write_image :top_timing_row
    
  # Sometimes there's a black bleed at the right of the page that can be confused with a timing mark. Detect and
  # remove it before checking that we have the correct number.
    if column_timing_marks[-1][1] == columns(:left_col)-1
      column_timing_marks.delete_at(-1)
    end
    
    # Sanity check
    if column_timing_marks.length != Top_timings_mark_count
      raise "Analysis failure on top timing marks: expected #{Top_timings_mark_count}, but got #{column_timing_marks.length}"
    end

  # Find midpoints of the column and row timing marks
    grid_columns = []
    convert_segs_to_mids column_timing_marks, grid_columns
    grid_rows = []
    convert_segs_to_mids row_timing_marks, grid_rows 
  
  # Find the row where the barcodes are (lined up with last timing mark) and take out a slice that's about the typical height
    barcode_row = grid_rows[-1]
    slice_row :cropped, barcode_row - g(Timing_mark_typheight)/2, barcode_row + g(Timing_mark_typheight)/2, :barcode_pixels

  # Clean them up  
    morphological_open :barcode_pixels, Morph_iter_barcode
    d_write_image :barcode_pixels, "barcodepx.gif"

  # Grab a single scanline from that
    slice_row :barcode_pixels, g(Timing_mark_typheight)/2, g(Timing_mark_typheight)/2+1, :barcode_pixels

  # Find the beg and end positions of each barcode segment
    barcode_segments = []
    find_black_segments :rows, :barcode_pixels, barcode_segments, g(Timing_mark_minwidth)

  # find their midpoints
    barcode_midpoints = []
    convert_segs_to_mids barcode_segments, barcode_midpoints

  # decode the barcode by lining them up with the corresponding column timing marks
    barcode_midpoints.each_with_index do |midpoint, barcodeindex|
      column_timing_marks.each_with_index do |colseg, timingindex|
        if colseg[0] <= midpoint && colseg[1] >= midpoint then
          @raw_barcode[barcodeindex] = timingindex
        end
      end
    end

  # Check that the barcodes make sense. We know for sure that the first and last barcode position is black  
    if @raw_barcode[0] !=0 || @raw_barcode[-1] != column_timing_marks.length-1
      raise "Analysis failure for barcode: #{@raw_barcode.inspect} [last one should be #{column_timing_marks.length-1}]"
    end

  # Go through all permutations (skipping the first and last one because they are the timing marks themselves) and see
  # if there's a filled out mark at the intersection

    grid_columns.each do | col |
      grid_rows.each do | row |
        next if row == grid_rows[0] || row == grid_rows[-1] || col == grid_columns[0] || col == grid_columns[-1] 
        score = inspect_checkbox :cropped, col-g(Vote_oval_width)/2, row-g(Vote_oval_height)/2, g(Vote_oval_width), g(Vote_oval_height)
        if score < (QuantumRange * 0.25).to_int then
          m_trace "r: #{row}, c: #{col} -> #{score}"
          @raw_marked_votes << [row, col]
        end
      end
    end  
  end
end