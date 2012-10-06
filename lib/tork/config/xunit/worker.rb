unless $tork_line_numbers.empty?
  test_file_lines = File.readlines($tork_test_file)
  test_names = $tork_line_numbers.map do |line|
    catch :found do
      # search backwards from the desired line number to
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
