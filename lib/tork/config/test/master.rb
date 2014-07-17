$LOAD_PATH.unshift 'test' unless $LOAD_PATH.include? 'test'
$LOAD_PATH.unshift 'lib' unless $LOAD_PATH.include? 'lib'
require 'test_helper' if File.exist? 'test/test_helper.rb'
require './test_helper' if File.exist? 'test_helper.rb'
require 'minitest/autorun' if defined? MiniTest
