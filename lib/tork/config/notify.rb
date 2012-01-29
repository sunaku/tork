require 'tork/config'

Tork::Config.test_event_hooks.push lambda {|message|
  event, test_file, line_numbers, log_file, worker_number, exit_status = message

  if event.to_sym == :fail
    title = [event.upcase, test_file].join(' ')

    notice = File.readlines(log_file).grep(/^\d+ \w+,/).join.
      gsub(/\e\[\d+(;\d+)?m/, '') # strip ANSI SGR escape codes

    Thread.new do # run in background
      system 'notify-send', '-i', 'dialog-error', title, notice or
      system 'growlnotify', '-a', 'Xcode', '-m', notice, title or
      system 'xmessage', '-timeout', '5', '-title', title, notice
    end
  end
}
