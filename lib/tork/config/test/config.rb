# people generally prefix or suffix their test file names with these labels
# https://en.wikibooks.org/wiki/Ruby_Programming/Unit_testing#Naming_Conventions
labels = %w[ test ts tc t ]
labels_glob = '{' + labels.join(',') + '}'
labels_grep = '(' + labels.join('|') + ')'

$tork_config_test_glob = "**/{#{labels_glob}_*,*_#{labels_glob}}.rb"
$tork_config_test_grep = %r{.*(\b#{labels_grep}_[^/]+|[^/]+_#{labels_grep})\.rb$}

ENV['TORK_CONFIGS'] += ':test' if Dir['test/', $tork_config_test_glob].any?
