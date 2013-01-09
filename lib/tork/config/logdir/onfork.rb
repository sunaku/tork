require 'fileutils'
dirname, basename = File.split($tork_log_file)
FileUtils.mkdir_p log_dir = File.join('log', dirname)
$tork_log_file = File.join(log_dir, basename)
