$LOAD_PATH.unshift 'lib', 'test', 'spec'

Dir['{test,spec}/{test,spec}_helper.rb'].each do |file|
  require File.basename(file, File.extname(file))
end
