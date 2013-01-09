dirname, basename = File.split($tork_log_file)
$tork_log_file = File.join(dirname, '.' + basename)
