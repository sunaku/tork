require 'tork/config'
require 'active_support/inflector'

Tork::Config.reabsorb_file_greps.push(
  %r<^config/.+\.(rb|yml)$>,
  %r<^db/schema\.rb$>,
  %r<^Gemfile\.lock$>
)

Tork::Config.test_file_globbers.update(
  %r<^(app|lib|test|spec)/.+\.rb$> => lambda do |path, matches|
    base = File.basename(path, '.rb')
    poly = ActiveSupport::Inflector.pluralize(base)
    "{test,spec}/**/{#{base},#{poly}_*}_{test,spec}.rb"
  end,

  %r<^(test|spec)/factories/.+_factory\.rb$> => lambda do |path, matches|
    base = File.basename(path, '_factory.rb')
    poly = ActiveSupport::Inflector.pluralize(base)
    "{test,spec}/**/{#{base},#{poly}_*}_{test,spec}.rb"
  end
)

Tork::Config.after_fork_hooks << proc do
  if defined? ActiveRecord::Base and
    ActiveRecord::Base.connection_pool.spec.config[:database] != ':memory:'
  then
    ActiveRecord::Base.connection.reconnect!
  end
end

begin
  require 'rails/railtie'
  class Tork::Railtie < Rails::Railtie
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
