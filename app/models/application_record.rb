class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  class << self
    def lock_by_name(name, timeout = 30, &block)
      begin
        connection.execute("SELECT GET_LOCK('#{name}', #{timeout});")
        yield
      ensure
        connection.execute("SELECT RELEASE_LOCK('#{name}');")
      end
    end
  end
end
