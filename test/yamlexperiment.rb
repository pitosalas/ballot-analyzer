require 'lib/iadsl'
require 'lib/premierballot'
require 'yaml'

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

class Test
  def initialize
    @array = [1,2,3,4,5,6]
    @big_array = [[1,2], [1,2], [1,2], [1,2], [1,2], [1,2], [1,2], [1,2], [1,2], [1,2], [1,2], [1,2], [1,2], [1,2]]
    def @big_array.to_yaml_style; :inline; end
    
    @hash = {:a,  :b, "this is a long string", 100, 200, [1,2,3,4,5]}
    @big_hash = [
      {:a => 2,  :b => 12, :string => "this is a long string", :x => 100, :y => 200, :aa => [1,2,3,4,5]},
      {:a => 2,  :b => 12, :string => "this is a long string", :x => 100, :y => 200, :aa => [1,2,3,4,5]},
      {:a => 2,  :b => 12, :string => "this is a long string", :x => 100, :y => 200, :aa => [1,2,3,4,5]},
      {:a => 2,  :b => 12, :string => "this is a long string", :x => 100, :y => 200, :aa => [1,2,3,4,5]}
    ]
  end

end

  f = File.open("balizer_1.yml", "w")
  f.puts Param1.to_yaml
  f.close
  
  t1 = Test.new
  t2 = Test.new
  a = [t1, t2]
  
  b = [
    {:a => 2,  :b => 12, :string => "this is a long string", :x => 100, :y => 200, :aa => [1,2,3,4,5]},
    {:a => 2,  :b => 12, :string => "this is a long string", :x => 100, :y => 200, :aa => [1,2,3,4,5]},
    {:a => 2,  :b => 12, :string => "this is a long string", :x => 100, :y => 200, :aa => [1,2,3,4,5]},
    {:a => 2,  :b => 12, :string => "this is a long string", :x => 100, :y => 200, :aa => [1,2,3,4,5]}
  ]
  
#  puts a.to_yaml
  big_array = [[1,2], [1,2], [1,2], [1,2]]
  def big_array.to_yaml_style; :inline; end

  puts a.to_yaml

#  require 'pp'
#  pp a
  
  config1 = YAML::load(File.open("balizer_1.yml"))
  puts config1.inspect
  