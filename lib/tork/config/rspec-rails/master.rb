$LOAD_PATH.unshift 'spec' unless $LOAD_PATH.include? 'spec'
require 'rails_helper' if File.exist? 'spec/rails_helper.rb'
require './rails_helper' if File.exist? 'rails_helper.rb'
