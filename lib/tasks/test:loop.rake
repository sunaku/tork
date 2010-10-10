namespace :test do
  desc 'Test changes continuously; pass RUN=1 to force initial run.'
  task :loop do |test_loop_task|
    ARGV.delete test_loop_task.name # interferes with RSpec test runner
    Rails.env = 'test' if defined? Rails and Rails.respond_to? :env= # Rails 3

    # absorb test execution overhead into master process
    overhead_file_glob = '{test,spec}/*_helper.rb'
    $LOAD_PATH.unshift 'lib' # for non-Rails applications' test or spec helper

    Dir[overhead_file_glob].each do |file|
      $LOAD_PATH.unshift file.pathmap('%d')
      require file.pathmap('%n')
    end

    # continuously watch for and test changed code
    started_at = Time.now
    last_ran_at = (ENV['RUN'] == '1') ? Time.at(0) : started_at
    loop do
      # figure out what test files need to be run
      test_files = {
        '{test,spec}/**/*_{test,spec}.rb' => '%p',
        '{app,lib}/**/*.rb' => '{test,spec}/**/%n_{test,spec}%x',
      }.
      map do |source_file_glob, test_file_pathmap|
        Dir[source_file_glob].
        select {|file| File.mtime(file) > last_ran_at }.
        map {|path| Dir[path.pathmap(test_file_pathmap)] }
      end.flatten.uniq

      # fork worker process to run the test files
      unless test_files.empty?
        last_ran_at = Time.now
        fork { test_files.each {|f| load f } }
        Process.wait
      end

      # re-absorb test execution overhead as necessary
      if Dir[overhead_file_glob].any? {|file| File.mtime(file) > started_at }
        exec $0, test_loop_task.name, *ARGV
      end

      sleep 1
    end
  end
end
