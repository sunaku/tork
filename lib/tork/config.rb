module Tork
  # Loads all Ruby scripts found having the given name in (1) the directories
  # specified in the given $TORK_CONFIGS search path, (2) the subdirectories
  # of lib/tork/config/, and (3) the user's .tork/ directory; in that order.
  #
  # @return [Array] paths of Ruby scripts that were loaded
  #
  def self.config name, search_path=ENV['TORK_CONFIGS']
    dirs = search_path.to_s.strip.split(/:+/).reject(&:empty?).uniq.
           map {|dir| [dir, __FILE__.sub(/\.rb$/, "/#{dir}")] }.flatten

    Dir.glob("{#{dirs.join(',')},.tork}/#{name}.rb") {|script| load script }
  end
end

ENV['TORK_CONFIGS'] ||= String.new.freeze # ENV values come frozen by default
Tork.config :config, '*'

unless ENV['TORK_CONFIGS_DETECTED'] =~ /\S/
  ENV['TORK_CONFIGS_DETECTED'] = $0
  Tork.config :detect, '*'
end
