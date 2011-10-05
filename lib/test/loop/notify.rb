require 'test/loop'

Test::Loop.after_each_test.push lambda {
  |test_file, log_file, run_status, started_at, elapsed_time, worker_id|

  unless run_status.success? or run_status.signaled?
    title = 'FAIL at %s in %0.1fs' % [started_at.strftime('%r'), elapsed_time]

    stats = File.readlines(log_file).grep(/^\d+ \w+,/).join.
      gsub(/\e\[\d+(;\d+)?m/, '') # strip ANSI SGR escape codes

    message = test_file + "\n" + stats

    Thread.new do # run in background
      system 'notify-send', '-i', 'dialog-error', title, message or
      system 'growlnotify', '-a', 'Xcode', '-m', message, title or
      system 'xmessage', '-timeout', '5', '-title', title, message
    end
  end
}
