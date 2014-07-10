ENV['TORK_CONFIGS'] += ':bundler' if Dir['Gemfile{,.lock}'].any?
