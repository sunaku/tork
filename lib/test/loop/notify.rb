require 'test/loop'

Test::Loop.after_each_test = lambda do |test_file, log_file, run_status, started_at, elapsed_time|
  unless run_status.success?
    title = 'FAIL at %s in %0.1fs' % [started_at.strftime('%r'), elapsed_time]
    message = test_file
    Thread.new do # run in background
      system 'notify-send', '-i', 'dialog-error', title, message or
      system 'growlnotify', '-a', 'Xcode', '-m', message, title or
      system 'xmessage', '-timeout', '5', '-title', title, message
    end
  end
end
