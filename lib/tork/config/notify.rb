require 'tork/config'
require 'set'

failed_test_files = Set.new

Tork::Config.test_event_hooks.push lambda {|message|
  event, test_file, line_numbers, log_file, worker_number, exit_status = message

  # make notifications edge-triggered: pass => fail or vice versa.
  # we do not care about pass => pass or fail => fail transitions.
  case event.to_sym
  when :fail
    if failed_test_files.add? test_file
      icon = 'dialog-error'
    end
  when :pass
    if line_numbers.empty? and failed_test_files.delete? test_file
      icon = 'dialog-information'
    end
  end

  if icon
    title = [event.upcase, test_file].join(' ')

    statistics = File.readlines(log_file).grep(/^\d+ \w+,/).join.
      gsub(/\e\[\d+(;\d+)?m/, '') # strip ANSI SGR escape codes

    Thread.new do # run in background
      system 'notify-send', '-i', icon, title, statistics or
      system 'growlnotify', '-a', 'Xcode', '-m', statistics, title or
      system 'xmessage', '-timeout', '5', '-title', title, statistics
    end
  end
}
