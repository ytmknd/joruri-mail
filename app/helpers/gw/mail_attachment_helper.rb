module Gw::MailAttachmentHelper
  def mail_attachment_view_model(at, options = {})
    {
      id: at.id,
      title: "#{at.title}(#{at.eng_unit})",
      image_is: at.image_is,
      css_class: at.css_class,
      name: at.name,
      tmp_id: nil
    }.merge(options)
  end
end
