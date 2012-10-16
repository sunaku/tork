module Tork
  # Loads all Ruby scripts found having the given name in (1) the directories
  # specified in the TORK_CONFIGS environment variable, (2) the subdirectories
  # of lib/tork/config/, and (3) the user's .tork/ directory; in that order.
  #
  # @return [Array] paths of Ruby scripts that were loaded
  #
  def self.config name
    dirs = ENV['TORK_CONFIGS'].to_s.strip.split(/:+/).reject(&:empty?).
      uniq.map {|dir| [dir, __FILE__.sub(/\.rb$/, "/#{dir}")] }.flatten

    Dir["{#{dirs.join(',')},.tork}/#{name}.rb"].each {|script| load script }
  end
end

Tork.config :config
