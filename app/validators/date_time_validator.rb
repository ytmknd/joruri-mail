class DateTimeValidator < ActiveModel::EachValidator
  def validate_each(record, attr, value)
    if value.present?
      begin
        DateTime.parse(value)
      rescue
        record.errors.add(attr, :invalid_datetime)
      end
    end
  end
end
