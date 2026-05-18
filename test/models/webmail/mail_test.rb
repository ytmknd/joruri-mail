require 'test_helper'

class Webmail::MailTest < ActiveSupport::TestCase
  Attachment = Struct.new(:name, :body)

  def test_zip_attachments_writes_unique_entries
    mail = Webmail::Mail.new
    attachments = [
      Attachment.new('report.txt', 'first'),
      Attachment.new('report.txt', 'second')
    ]
    mail.define_singleton_method(:attachments) { attachments }

    data = mail.zip_attachments

    Zip::File.open_buffer(data) do |zip|
      assert_equal ['report.txt', 'report_1.txt'], zip.entries.map(&:name)
      assert_equal 'first', zip.read('report.txt')
      assert_equal 'second', zip.read('report_1.txt')
    end
  end
end
