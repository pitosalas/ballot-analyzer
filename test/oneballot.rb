require '../lib/iadsl.rb'
require '../lib/premierballot.rb'
require 'yaml'


ruby_debug = true
ruby_profile = false

if ruby_debug
  require "ruby-debug"
  Debugger.settings[:autolist] = 1 # list nearby lines on stop
  Debugger.settings[:autoeval] = 1
  Debugger.start
end

if ruby_profile
  require 'ruby-prof'
  RubyProf.start
end

class Array
  def to_yaml_style; :inline; end
end

inparams = {:forensics => :on, :logging => :on, :target_dpi => 72, :max_skew => 0.15}
outparams = []

prem_ballot = PremierBallot.new inparams, outparams

#prem_ballot.file_to_process = "/Volumes/ExternalHD2/Ballots/Leon/EV976-29/work/2818-2.tif"
#prem_ballot.file_to_process = "/Volumes/ExternalHD2/Ballots/Leon/Pitobasement/work/432Leon200dpibw422.tif"
#prem_ballot.file_to_process = "weird.tif"
#prem_ballot.file_to_process = "/Volumes/ExternalHD2/Ballots/Humboldt/00/01/000121.jpg"
#prem_ballot.file_to_process = "/Volumes/ExternalHD2/Ballots/Leon/AB946-7/125129-2.TIF"

prem_ballot.process_file "/Volumes/ExternalHD2/Ballots/Humboldt/00/01/000100.jpg"

puts outparams.to_yaml









