require 'tork/config'

Tork::Config.before_fork_hooks.unshift lambda {
  |test_file, line_numbers, log_file, worker_number|

  dirname, basename = File.split(log_file)
  log_file.replace File.join(dirname, '.' + basename)
}
