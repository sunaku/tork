# uncache Rails classes accessed by devise_for() calls in config/routes.rb
Devise.mappings.each_value do |mapping|
  ActiveSupport::Dependencies.remove_constant mapping.class_name
  ActiveSupport::Dependencies.loaded.delete ActiveSupport::Dependencies.
    search_for_file(mapping.class_name.underscore).gsub(/\.rb\z/, '')
end
