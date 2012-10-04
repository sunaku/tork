dirname, basename = File.split($tork_log_file)
$tork_log_file.replace File.join(dirname, '.' + basename)
