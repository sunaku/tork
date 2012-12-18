# ensure that each mapping still has
# a proper klass

Devise.mappings.each_value do |mapping|
  mapping.instance_variable_set :@klass, Devise.ref(mapping.class_name.constantize)
end
