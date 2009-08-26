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

class PbProcessor
  
#
# Defaults for values coming in via params
#
  Target_DPI_default = 300    # Default DPI that image is converted to before processing
  Max_skew_default = 0.15     # How skewed does the image have to be to require a rotate (which is very expensive)
    
#
# Initialize the instance with the parameters desired for the overall run
#     Val_params says what the expected Keys and values are in the params argument  
#     params is the input argument with the paramteters for the run
#     res_hash is a hash that will be filled in with expected results. Caller will supply an array to
#             which a hash with result of this run will be added.
Val_params = {
  :target_dpi => Fixnum,
  :upstream => UpstreamReporter,
  :max_skew => Float,
  :dir_style => Symbol,
  :path => String
}

  def initialize(inparams, outlist)  
    raise "PremierBallot invalid params" unless ! inparams.nil? && valid_params?(inparams, Val_params)
    @target_dpi = inparams[:target_dpi] || Target_DPI_default
    @max_skew = inparams[:max_skew] || Max_skew_default
    @upstream = inparams[:upstream]

    @array_of_results = outlist
    @params = inparams
    
    diagnostics :trace if @debugging == :on
    @analyzer = PbAnalyzer.new
  end

#
# Validate params structure.
#
  def valid_params? params, val_params
    return false unless params.class == Hash
    params.each_pair do |key, val|
      expected_type = val_params[key]
      if expected_type.nil? 
        puts "Invalid key in params: #{key}"
        return false
      elsif val.class != expected_type
        puts "Unexpected value in params: #{key} => #{val}. Expected #{expected_type}, found #{val.class}"
        return false
      end
    end
    true
  end
    
#
# Compute binary value of barcode from on and off bars
#
  def compute_barcode(barcode_vect)
    barcode_vect.inject {|m, v| m+2 ** v}
  end

#
# Given a barcode value, extract the bits that (we think) mean the ballot style
#
  def bitfield(from,to,val)
   return ( val>>from ) & ( (2 << (to - from) ) - 1)
  end
  
#
# Given scanned analysis of barcode, deduce the ballot style
#
  def deduce_ballot_style(barcode_vect)
    barcode_value = compute_barcode(barcode_vect)
    bitfield(15, 18, barcode_value)
  end
  
#
# driver: Process a two level directory structure
#
  def process_2level_directory_structure
    raise "Invalid dir_style parameter" unless @params[:dir_style] == :two_level
    @dir_walker = DirectoryWalker.new
    @dir_walker.walk_2level_path @params[:path] do |fname|
      process_single_file fname
    end      
  end
  
#
# driver: Process a simple directory structure
#
  def process_directory
    raise "invalid dir_style parameter" unless @params[:dir_style] == :simple
    @dir_walker = DirectoryWalker.new
    @dir_walker.walk_directory @params[:path] do |fname|
      process_single_file fname
    end
  end
  
#
# driver: Process a single file, specified in parameter
#
  def process_single_file fname
    @result = Hash.new
    @array_of_results << @result
    @result[:filename] = fname
    @filename = fname
    @upstream.stream("ballot #{fname}")
    begin
      @analyzer.analyze_ballot_image fname, @target_dpi, @max_skew, @result, @upstream
      @result[:ballot_style] = deduce_ballot_style(@result[:raw_barcode])
      @upstream.stream("success")
    rescue
      @upstream.stream("failure")
    end
  end
end