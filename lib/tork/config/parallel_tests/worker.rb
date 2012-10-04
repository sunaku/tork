# parallel_tests expects the sequence "", "2", "3", "4", ...
if $tork_worker_number > 0
  ENV['TEST_ENV_NUMBER'] = ($tork_worker_number + 1).to_s
end
