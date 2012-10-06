module Tork
  CONFIG_DIRS = ENV['TORK_CONFIGS'].to_s.strip.split(/:+/).reject(&:empty?).
    uniq.map {|dir| [dir, __FILE__.sub(/\.rb$/, "/#{dir}")] }.flatten

  # Loads the Ruby script having the given name from the first directory that
  # contains it from among (1) the .tork/ directory, (2) the directories in
  # the CONFIG_DIRS environment variable, and (3) the tork config/ directory.
  def self.config name
    Dir["{#{CONFIG_DIRS.join(',')},.tork}/#{name}.rb"].each do |script|
      load script
    end
  end
end
