require 'rubygems'
require 'iadsl'

if true
  require 'ruby-prof'
  RubyProf.start
end

def test1
  open_image :ballot, "/Volumes/ExternalHD2/Ballots/Leon/Pitobasement/work/432Leon200dpibw422.tif"
  puts "Resolution: #{(image_dpi :ballot).inspect}"
  img = get_image :ballot
  img.sample!(0.5)
  img.density = "100x100"
  img.write "test-sample-0.5.tif"
end
  
def test2
  open_image :ballot, "/Volumes/ExternalHD2/Ballots/Leon/Pitobasement/work/432Leon200dpibw422.tif"
  img = get_image :ballot
  img.resize!(0.5)
  img.write "test-resize-0.5.tif"
end
  
def test3
  open_image :ballot, "/Volumes/ExternalHD2/Ballots/Leon/Pitobasement/work/432Leon200dpibw422.tif"
  resample :ballot, 100
  write_image :ballot, "test-ballot-resample.tif"
end

  test1
  test2
  test3

# Print a flat profile to text
  result = RubyProf.stop
  printer = RubyProf::GraphHtmlPrinter.new(result)
  printer.print(File.new("resample.html", "w"), :min_percent=>0)
