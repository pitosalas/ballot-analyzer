require 'premierballot'

ruby_debug = false
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

#path = "/Volumes/ExternalHD2/Ballots/Leon/EV976-29/work/"
#path = "/Volumes/ExternalHD2/Ballots/Leon/Pitobasement/work/"
#path = "/Volumes/ExternalHD2/Ballots/Leon/GETest/"
path = "/Volumes/ExternalHD2/Ballots/Humboldt/00/01/"
passed = 0
failed = 0

prem_ballot = PremierBallot.new(72)
#prem_ballot.diags :profile unless ruby_profile
#prem_ballot.diags :trace

Dir.foreach(path) do |name|
  next_file = Pathname.new(path)+Pathname.new(name)
  begin
    next if name[0] == 46
    prem_ballot.file_to_process = next_file
    prem_ballot.process_one
    puts "\nfile: #{prem_ballot.file_to_process}"
    puts "barcode: #{prem_ballot.raw_barcode.inspect}"
    puts "votes:  #{prem_ballot.raw_marked_votes.length} \n #{prem_ballot.raw_marked_votes.inspect}"
    passed += 1

  rescue => err
    puts "Failed to figure out #{next_file}: #{err}"
    failed += 1
  end
end

puts "Passed: #{passed}, Failed: #{failed}"

prem_ballot.diags :end unless ruby_profile

if ruby_profile 
# Print a flat profile to text
  result = RubyProf.stop
  printer = RubyProf::GraphHtmlPrinter.new(result)
  printer.print(File.new("foo2.html", "w"), :min_percent=>0)
end