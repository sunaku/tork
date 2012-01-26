require 'tork/config'
require 'fileutils'

Tork::Config.before_fork_hooks.unshift lambda {
  |worker_number, log_file, test_file, line_numbers|

  dirname, basename = File.split(log_file)
  FileUtils.mkdir_p log_dir = File.join('log', dirname)
  log_file.replace File.join(log_dir, basename)
}
