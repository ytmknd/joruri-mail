class Sys::Lib::Ldap::Entry
  def initialize(connection, attributes = {})
    attributes = attributes.each_with_object({}) do |(key, val), hash|
      hash[key.to_s] = Array(val).map do |v|
        v.to_s.force_encoding("utf-8")
      end
    end

    @connection = connection
    @attributes = attributes
    @primary     = nil
    @filter      = nil
  end
  
  def search(filter, options = {})
    filter = "(#{filter.join(')(')})" if filter.class == Array
    filter = "#{filter}(&#{@filter})"
    options[:class] ||= self.class
    return @connection.search(filter, options)
  end
  
  def find(id, options = {})
    filter = "(#{@primary}=#{id})(&#{@filter})"
    options[:class] ||= self.class
    return @connection.search(filter, options)[0]
  end
  
  def attributes
    return @attributes
  end
  
  def get(name, position = 0)
    name = name.to_s
    values = @attributes[name] || @attributes[name.downcase]
    if position == :all
      return values ? values : []
    elsif values
      return values[position]
    else
      return nil
    end
  end
  
  def dn
    get(:dn)
  end
end
