# remove the classes loaded by devise

Devise.mappings.each_value do |mapping|
  ActiveSupport::Dependencies.remove_constant mapping.class_name
  file_name = ActiveSupport::Dependencies.
    search_for_file(mapping.class_name.underscore).
    gsub(/\.rb\z/, '')
  ActiveSupport::Dependencies.loaded.delete file_name
end
