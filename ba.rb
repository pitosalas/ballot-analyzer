require 'lib/iadsl'
require 'lib/premierballot'

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

Param1 = {
  :system => :premier,
  :run_dpi => 150,
  :in_file_processing => :single,
  :in_file_info => "/Volumes/ExternalHD2/Ballots/Leon/AB946-7/125129-2.TIF",
  :out_file_format => :yaml,
  :out_file_info => "result/"
}

Param2 = {
  :system => :premier,
  :run_dpi => 150,
  :in_file_processing => :directory,
  :in_file_info => "/Volumes/ExternalHD2/Ballots/Leon/AB946-7/",
  :out_file_format => :yaml,
  :out_file_info => "result/"
}

Param3 = {
  :system => :premier,
  :run_dpi => 150,
  :in_file_processing => :nested,
  :in_file_info => "/Volumes/ExternalHD2/Ballots/Leon/AB946-7/",
  :out_file_format => :yaml,
  :out_file_info => "result/"
}

  f = File.open("balizer_1.yml", "w")
  f.puts Param1.to_yaml
  f.close
  
  config1 = YAML::load(File.open("balizer_1.yml"))
  puts config1.inspect
  