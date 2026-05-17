module Mail
  class DispositionNotificationToField < Mail::CommonAddressField
    NAME = 'Disposition-Notification-To'
    FIELD_NAME = 'disposition-notification-to'
    CAPITALIZED_FIELD = NAME

    include FieldWithIso2022JpEncoding
  end
end
