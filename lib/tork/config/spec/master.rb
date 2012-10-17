$LOAD_PATH.unshift 'spec' unless $LOAD_PATH.include? 'spec'
$LOAD_PATH.unshift 'lib' unless $LOAD_PATH.include? 'lib'
require 'spec_helper' if File.exist? 'spec/spec_helper.rb'
