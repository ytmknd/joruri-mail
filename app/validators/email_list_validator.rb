class EmailListValidator < ActiveModel::EachValidator
  def validate_each(record, attr, value)
    if value.present?
      addrs = Email.parse_list(value, raise_errors: true)
      if addrs.blank? ||
         addrs.any? { |addr| !Email.valid_email?(addr.address) }
        record.errors.add(attr, :invalid_email_list)
      end
    end
  rescue Mail::Field::ParseError => e
    record.errors.add(attr, :invalid_email_list)
  end
end
