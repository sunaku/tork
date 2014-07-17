$tork_config_spec_glob = '**/{spec_*,*_spec}.rb'
$tork_config_spec_grep = %r{.*(\bspec_[^/]+|[^/]+_spec)\.rb$}

ENV['TORK_CONFIGS'] += ':spec' if Dir['spec/', $tork_config_spec_glob].any?
