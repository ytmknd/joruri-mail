require_relative 'fields/disposition_notification_to_field'

module Mail
  class Field
    # Add 'Disposition-Notification-To' field support
    STRUCTURED_FIELDS << 'disposition-notification-to'
    FIELDS_MAP['disposition-notification-to'] = DispositionNotificationToField
    FIELD_NAME_MAP['disposition-notification-to'] = DispositionNotificationToField::CAPITALIZED_FIELD
  end
end
