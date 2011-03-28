require 'test/loop'

Test::Loop.reabsorb_file_globs.push(
  'config/**/*.{rb,yml}',
  'test/factories/*.rb',
  'Gemfile.lock'
)

Test::Loop.test_file_matchers['app/**/*.rb'] =
  Test::Loop.test_file_matchers['lib/**/*.rb']
