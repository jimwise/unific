#!/usr/bin/ruby

require 'rubygems'
require 'unific'

KEYS = [ :first, :last, :age, :occupation ]
DATA = [
        { :first => "John", :last => "Smith", :age => 40, :occupation => "yak shaver" },
        { :first => "Joe",  :last => "Bloe",  :age => 30, :occupation => "cat herder" },
        { :first => "Jack", :last => "White", :age => 40, :occupation => "telephone sanitizer" },
        { :first => "John", :last => "NotSmith", :age => 90, :occupation => "inspirational speaker" }
       ]

# q is a hash with one or more values filled in
def query q
  q2 = {}
# note that as of Ruby 1.9, order matters
  KEYS.each {|k| q2[k] = q[k] = Unific::_}
  r = DATA.select {|d| Unific::unify d, q2}
end

Unific::trace if ENV['UNIFIC_TRACE']

johns = query :first => "John"
forties = query :age => 40
john_forties = query :first => "John", :age => 40

puts "People named John:"
johns.each {|d| puts "found: #{d[:first]} #{d[:last]}"}

puts

puts "Forty-year-olds:"
forties.each {|d| puts "found: #{d[:first]} #{d[:last]}"}

puts

puts "Forty-year-old people named John:"
john_forties.each {|d| puts "found: #{d[:first]} #{d[:last]}"}
