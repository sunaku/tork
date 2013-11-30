# although inherited as a file descriptor during the fork(), the database
# connection cannot be shared between the master and its workers or amongst
# the workers themselves because access to the file descriptor isn't mutexed
if defined? ActiveRecord::Base
  base = ActiveRecord::Base

  info =
    if base.respond_to? :connection_info        # rails >= 3.1.0
      base.connection_info
    elsif base.respond_to? :connection_pool     # rails >= 2.2.1
      base.connection_pool.spec.config
    else
      warn "#{$0}: config/rails/worker: could not read connection information"
      {}
    end

  # in-memory databases are private to each process so they're safely fork()ed
  base.connection.reconnect! unless info[:database] == ':memory:'
end
