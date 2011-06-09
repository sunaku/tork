require 'test/loop'

Test::Loop.reabsorb_file_globs.push(
  'config/**/*.{rb,yml}',
  'db/schema.rb',
  'Gemfile.lock'
)

Test::Loop.test_file_matchers['{app,lib,test,spec}/**/*.rb'] =
  Test::Loop.test_file_matchers.delete('lib/**/*.rb')

Test::Loop.test_file_matchers['{test,spec}/factories/**/*_factory.rb'] =
  lambda do |path|
    base = File.basename(path, '_factory.rb')
    "{test,spec}/**/#{base}_{test,spec}.rb"
  end

require 'rails/railtie'
Class.new Rails::Railtie do
  config.before_initialize do |app|
    if app.config.cache_classes
      warn "test-loop: Setting #{app.class}.config.cache_classes = false"
      app.config.cache_classes = false
    end
  end
end
