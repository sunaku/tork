require 'active_support/inflector'

Tork::Driver::REABSORB_FILE_GREPS.push(
  %r{^config/.+\.(rb|yml)$},
  %r{^db/schema\.rb$},
  %r{^Gemfile\.lock$}
)

Tork::Driver::TEST_FILE_GLOBBERS.update(
  %r{^(app|lib|test|spec)/.*?([^/]+?)(_factory)?\.rb$} => lambda do |matches|
    single = matches[2]
    plural = ActiveSupport::Inflector.pluralize(single)
    "{test,spec}/**/{#{single},#{plural}_*}_{test,spec}.rb"
  end,

  %r{^app/views/(.+)/} => lambda do |matches|
    plural = File.basename(matches[1])
    single = ActiveSupport::Inflector.singularize(plural)
    "{test,spec}/**/{#{single},#{plural}_*}_{test,spec}.rb"
  end
)
