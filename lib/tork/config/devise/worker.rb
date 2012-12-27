# restore Rails classes accessed by devise_for() calls in config/routes.rb
Devise.mappings.each_value do |mapping|
  # NOTE: constantize() makes Rails find and load misssing class definitions
  mapping.instance_variable_set :@klass, Devise.ref(mapping.class_name.constantize)
end
