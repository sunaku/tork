if $tork_test_file.start_with? 'spec/' and $tork_line_numbers.any?
  $tork_line_numbers.each do |line|
    ARGV.push '--line_number', line.to_s
  end
end
