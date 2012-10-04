# instruct the testing framework to only run those
# tests that are defined on the given line numbers
case File.basename($tork_test_file)
when /(\b|_)spec(\b|_).*\.rb$/ # RSpec
  $tork_line_numbers.each do |line|
    ARGV.push '--line_number', line.to_s
  end

when /(\b|_)test(\b|_).*\.rb$/ # Test::Unit
  # find which tests have changed inside the test file
  test_file_lines = File.readlines($tork_test_file)
  test_names = $tork_line_numbers.map do |line|
    catch :found do
      # search backwards from the line that changed up to
      # the first line in the file for test definitions
      line.downto(0) do |i|
        test_name =
          case test_file_lines[i]
          when /^\s*def\s+test_(\w+)/ then $1
          when /^\s*(test|context|should|describe|it)\b.+?(['"])(.*?)\2/
            # elide string interpolation and invalid method name characters
            $3.gsub(/\#\{.*?\}/, ' ').strip.gsub(/\W+/, '.*')
          end \
        and throw :found, test_name
      end; nil # prevent unsuccessful search from returning an integer
    end
  end.compact.uniq

  unless test_names.empty?
    ARGV.push '--name', "/(?i:#{test_names.join('|')})/"
  end
end
