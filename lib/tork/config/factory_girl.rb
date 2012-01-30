require 'tork/config'

Tork::Config.before_fork_hooks.push proc {
  require 'factory_girl'
  FactoryGirl.factories.clear
}

Tork::Config.after_fork_hooks.push proc {
  FactoryGirl.find_definitions
}
