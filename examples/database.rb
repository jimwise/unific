require 'rubygems'
require 'unific'

DATA = [
        { :first => "John", :last => "Smith", :age => 40, :occupation => "yak shaver" },
        { :first => "Joe",  :last => "Bloe",  :age => 30, :occupation => "cat herder" },
        { :first => "Jack", :last => "White", :age => 40, :occupation => "telephone sanitizer" },
        { :first => "John", :last => "NotSmith", :age => 90, :occupation => "inspirational speaker" }
       ]

def query q
  r = DATA.select {|d| Unific::unify d, q}
end

johns = query :first => "John", :last => Unific::_, :age => Unific::_, :occupation => Unific::_

johns.each {|d| puts "found: #{d[:first]} #{d[:last]}"}
