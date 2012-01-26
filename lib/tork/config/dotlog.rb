require 'tork/config'

Tork::Config.before_fork_hooks.unshift lambda {
  |worker_number, log_file, test_file, line_numbers|

  dirname, basename = File.split(log_file)
  log_file.replace File.join(dirname, '.' + basename)
}
