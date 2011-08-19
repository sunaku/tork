require 'test/loop'
require 'active_support/inflector'

Test::Loop.reabsorb_file_globs.push(
  'config/**/*.{rb,yml}',
  'db/schema.rb',
  'Gemfile.lock'
)

Test::Loop.test_file_matchers['{app,lib,test,spec}/**/*.rb'] =
  lambda do |path|
    base = File.basename(path, '.rb')
    poly = ActiveSupport::Inflector.pluralize(base)
    "{test,spec}/**/{#{base},#{poly}_*}_{test,spec}.rb"
  end

Test::Loop.test_file_matchers['{test,spec}/factories/**/*_factory.rb'] =
  lambda do |path|
    base = File.basename(path, '_factory.rb')
    poly = ActiveSupport::Inflector.pluralize(base)
    "{test,spec}/**/{#{base},#{poly}_*}_{test,spec}.rb"
  end

begin
  require 'rails/railtie'
  Class.new Rails::Railtie do
    config.before_initialize do |app|
      if app.config.cache_classes
        warn "test-loop: Setting #{app.class}.config.cache_classes = false"
        app.config.cache_classes = false
      end
    end
  end
rescue LoadError
  warn "test-loop: Railtie not available; please manually set:\n\t"\
       "config.cache_classes = false"
end
