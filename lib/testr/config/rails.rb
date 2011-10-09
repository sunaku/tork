require 'testr/config'
require 'active_support/inflector'

TestR::Config.reabsorb_file_globs.push(
  'config/**/*.{rb,yml}',
  'db/schema.rb',
  'Gemfile.lock'
)

TestR::Config.test_file_matchers[%r<^(app|lib|test|spec)/.+\.rb$>] =
  lambda do |path|
    base = File.basename(path, '.rb')
    poly = ActiveSupport::Inflector.pluralize(base)
    "{test,spec}/**/{#{base},#{poly}_*}_{test,spec}.rb"
  end

TestR::Config.test_file_matchers[%r<^(test|spec)/factories/.+_factory\.rb$>] =
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
        warn "testr/config/rails: Setting #{app.class}.config.cache_classes = false"
        app.config.cache_classes = false
      end
    end
  end
rescue LoadError
  warn "testr/config/rails: Railtie not available; please manually set:\n\t"\
       "config.cache_classes = false"
end
