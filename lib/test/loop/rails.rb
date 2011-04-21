require 'test/loop'

Test::Loop.reabsorb_file_globs.push(
  'config/**/*.{rb,yml}',
  'Gemfile.lock'
)

Test::Loop.test_file_matchers['app/**/*.rb'] =
  Test::Loop.test_file_matchers['lib/**/*.rb']

require 'rails/railtie'
Class.new Rails::Railtie do
  config.before_initialize do |app|
    if app.config.cache_classes
      warn "test-loop: Setting #{app.class}.config.cache_classes = false"
      app.config.cache_classes = false
    end
  end
end
