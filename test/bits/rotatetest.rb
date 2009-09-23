require 'rubygems'
require 'iadsl'

if true
  require 'ruby-prof'
  RubyProf.start
end


10.times do 
  open_image :ballot, "432Leon200dpibw001.tif"
  binarize :ballot
  resample :ballot, 72
  rotate :ballot, 1.0
  write_image :ballot, "bb.tif"
  diagnostics :end
end

# Print a flat profile to text
  result = RubyProf.stop
  printer = RubyProf::GraphHtmlPrinter.new(result)
  printer.print(File.new("foo5.html", "w"), :min_percent=>0)
