class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  class << self
    def copy_table(src, dest)
      quoted_src = connection.quote_table_name(src)
      quoted_dest = connection.quote_table_name(dest)
      connection.execute("DROP TABLE IF EXISTS #{quoted_dest}")
      connection.execute("CREATE TABLE #{quoted_dest} LIKE #{quoted_src}")
      connection.execute("INSERT INTO #{quoted_dest} SELECT * FROM #{quoted_src}")
    end

    def lock_by_name(name, timeout = 30, &block)
      begin
        connection.execute(sanitize_sql(["SELECT GET_LOCK(?, ?)", name, timeout]))
        yield
      ensure
        connection.execute(sanitize_sql(["SELECT RELEASE_LOCK(?)", name]))
      end
    end
  end
end
