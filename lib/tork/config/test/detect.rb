ENV['TORK_CONFIGS'] += ':test' if Dir['test/', $tork_config_test_glob].any?
