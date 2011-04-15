if defined? Rails
  Test::Loop.reabsorb_file_globs.push(
    'config/**/*.{rb,yml}',
    'test/factories/*.rb',
    'Gemfile.lock'
  )

  Test::Loop.test_file_matchers['app/**/*.rb'] =
    Test::Loop.test_file_matchers['lib/**/*.rb']

  if defined? Rails::Railtie
    Class.new Rails::Railtie do
      config.before_initialize do |app|
        if app.config.cache_classes
          warn "test-loop: Setting #{app.class}.config.cache_classes = false"
          app.config.cache_classes = false
        end
      end
    end
  end
end
