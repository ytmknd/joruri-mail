class DateValidator < ActiveModel::EachValidator
  def validate_each(record, attr, value)
    if value.present?
      begin
        DateTime.parse(value)
      rescue
        record.errors.add(attr, :invalid_date)
      end
    end
  end
end
