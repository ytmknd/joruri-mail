require 'test_helper'

class Webmail::MailboxTest < ActiveSupport::TestCase
  def test_counter_defaults_round_trip_with_full_insert
    mailbox = Webmail::Mailbox.new(name: 'INBOX', title: 'INBOX', delim: '.')

    assert_equal 0, mailbox.messages
    assert_equal 0, mailbox.unseen
    assert_equal 0, mailbox.recent

    mailbox.save!(validate: false)
    mailbox.reload

    assert_equal 0, mailbox.messages
    assert_equal 0, mailbox.unseen
    assert_equal 0, mailbox.recent
  end
end
