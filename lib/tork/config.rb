module Tork
  CONFIG_ROOT = __FILE__.sub(/\.rb$/, '')
  CONFIG_DIRS = ENV['TORK_CONFIGS'].to_s.strip.split(/:+/).unshift('default').
    uniq.flat_map {|d| d += '/'; [d, ".tork/#{d}", "#{CONFIG_ROOT}/#{d}"] }

  # Loads configuration files that have the given name from directories
  # specified in the CONFIG_DIRS environment variable.
  def self.config name
    Dir["{#{CONFIG_DIRS.join(',')}}/#{name}.rb"].each {|f| load f }
  end
end
