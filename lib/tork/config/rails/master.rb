begin
  require 'rails/railtie'
  class Tork::Railtie < Rails::Railtie
    config.before_initialize do |app|
      app.config.cache_classes = false
      ActiveSupport::Dependencies.mechanism = :load
    end
  end
rescue LoadError => error
  warn "tork/config/rails/master: could not set configuration using railties;\n"\
       "you will have to add the following to your test environment manually:\n\t"\
       'config.cache_classes = false'
end
