begin
  require 'rails/railtie'
  class Tork::Railtie < Rails::Railtie
    config.before_initialize do |app|
      app.config.cache_classes = false
      ActiveSupport::Dependencies.mechanism = :load
    end

    # if using an sqlite3 database for the test environment, make
    # it an in-memory database to support parallel test execution
    config.after_initialize do
      current = ActiveRecord::Base.connection_config
      memory = {:adapter => 'sqlite3', :database => ':memory:'}

      if current[:adapter] == memory[:adapter]
        # ensure that the sqlite3 database is in-memory
        unless current[:database] == memory[:database]
          ActiveRecord::Base.establish_connection memory
        end

        # create application schema if it does not exist
        unless File.exist? schema = "#{Rails.root}/db/schema.rb"
          system 'rake', '--trace', 'db:schema:dump', 'RAILS_ENV=development'
        end

        # apply application schema to in-memory database
        silence_stream(STDOUT) { load schema }
        ActiveRecord::Base.connection.schema_cache.clear!

        # load any seed data into the in-memory database
        if File.exist? seeds = "#{Rails.root}/db/seeds.rb"
          load seeds
        end

        # keep sub-Rails connected to in-memory database
        # e.g. when another Rails is started by Capybara
        # http://www.spacevatican.org/2012/8/18/threading-the-rat/
        class << ActiveRecord::Base
          memory_database_connection = ActiveRecord::Base.connection
          define_method(:connection) { memory_database_connection }
        end
      end
    end
  end
rescue LoadError
  warn "tork/config/rails/master: could not set configuration using railties;\n"\
       "you will have to add the following to your test environment manually:\n\t"\
       'config.cache_classes = false'
end
