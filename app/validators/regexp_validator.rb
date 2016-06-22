class RegexpValidator < ActiveModel::EachValidator
  def validate_each(record, attr, value)
    if value.present?
      begin
        Regexp.new(value)
      rescue => e
        record.errors.add(attr, :invalid_regexp, error: e.to_s)
      end
    end
  end
end
