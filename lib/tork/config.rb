module Tork
  CONFIG_ROOT = __FILE__.sub(/\.rb$/, '')
  CONFIG_DIRS = ENV['TORK_CONFIGS'].to_s.strip.split(/:+/).reject(&:empty?).
    uniq.map {|dir| [dir, "#{CONFIG_ROOT}/#{dir}"] }.flatten.
    unshift('.tork').push("#{CONFIG_ROOT}/default")

  # Loads the Ruby script having the given name from the first directory that
  # contains it from among (1) the .tork/ directory, (2) the directories in
  # the CONFIG_DIRS environment variable, and (3) the tork config/ directory.
  def self.config name
    if script = Dir["{#{CONFIG_DIRS.join(',')}}/#{name}.rb"].first
      load script
    end
  end
end
