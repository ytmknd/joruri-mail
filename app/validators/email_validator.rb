class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attr, value)
    if value.present?
      addr = Email.parse(value, raise_errors: true)
      if addr.blank? ||
         addr.address.blank? ||
         (options[:strict] && !Email.valid_email?(addr.address)) ||
         (options[:only_address] && addr.name.present?)
        record.errors.add(attr, :invalid_email)
      end
    end
  rescue Mail::Field::ParseError => e
    record.errors.add(attr, :invalid_email)
  end
end
