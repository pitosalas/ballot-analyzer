require '../lib/iadsl.rb'
require '../lib/premierballot.rb'

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


prem_ballot = PremierBallot.new

prem_ballot.diags :profile
prem_ballot.diags :trace

#prem_ballot.file_to_process = "/Volumes/ExternalHD2/Ballots/Leon/EV976-29/work/2818-2.tif"
#prem_ballot.file_to_process = "/Volumes/ExternalHD2/Ballots/Leon/Pitobasement/work/432Leon200dpibw422.tif"
#prem_ballot.file_to_process = "/Volumes/ExternalHD2/Ballots/Humboldt/00/01/000100.jpg"
#prem_ballot.file_to_process = "weird.tif"
#prem_ballot.file_to_process = "/Volumes/ExternalHD2/Ballots/Humboldt/00/01/000121.jpg"
prem_ballot.file_to_process = "/Volumes/ExternalHD2/Ballots/Leon/AB946-7/125129-2.TIF"


prem_ballot.process_one

puts "file: #{prem_ballot.file_to_process}"
puts "barcode: #{prem_ballot.raw_barcode.inspect}"
puts "votes: #{prem_ballot.raw_marked_votes.length}"
puts "          #{prem_ballot.raw_marked_votes.inspect}"

prem_ballot.diags :end
