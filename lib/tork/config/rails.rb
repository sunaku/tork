require 'tork/config'
require 'active_support/inflector'

Tork::Config.reabsorb_file_greps.push(
  %r<^config/.+\.(rb|yml)$>,
  %r<^db/schema\.rb$>,
  %r<^Gemfile\.lock$>
)

Tork::Config.test_file_globbers[%r<^(app|lib|test|spec)/.+\.rb$>] =
  lambda do |path|
    base = File.basename(path, '.rb')
    poly = ActiveSupport::Inflector.pluralize(base)
    "{test,spec}/**/{#{base},#{poly}_*}_{test,spec}.rb"
  end

Tork::Config.test_file_globbers[%r<^(test|spec)/factories/.+_factory\.rb$>] =
  lambda do |path|
    base = File.basename(path, '_factory.rb')
    poly = ActiveSupport::Inflector.pluralize(base)
    "{test,spec}/**/{#{base},#{poly}_*}_{test,spec}.rb"
  end

Tork::Config.after_fork_hooks << proc do
  unless ActiveRecord::Base.connection_config[:database] == ':memory:'
    ActiveRecord::Base.connection.reconnect!
  end
end

begin
  require 'rails/railtie'
  Class.new Rails::Railtie do
    config.before_initialize do |app|
      if app.config.cache_classes
        warn "tork/config/rails: Setting #{app.class}.config.cache_classes = false"
        app.config.cache_classes = false
      end
    end
  end
rescue LoadError
  warn "tork/config/rails: Railtie not available; please manually set:\n\t"\
       "config.cache_classes = false"
end
