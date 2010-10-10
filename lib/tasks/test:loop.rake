namespace :test do
  desc 'Test changes; Ctrl-Z forces; Ctrl-\ reloads; Ctrl-C quits.'
  task :loop do |test_loop_task|
    ENV['RAILS_ENV'] = 'test' # for Rails
    ARGV.delete test_loop_task.name # obstructs RSpec
    exec 'ruby', File.expand_path('../../test:loop.rb', __FILE__), *ARGV
  end
end
