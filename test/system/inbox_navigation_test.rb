require "application_system_test_case"

class InboxNavigationTest < ApplicationSystemTestCase
  test "logged-in admin reaches inbox and can open compose page" do
    login_as_admin

    # Inbox page loads with the mail list area visible.
    assert_current_path(/\/webmail\//)
    assert_text "受信トレイ"

    # Navigate to compose page.
    visit "/webmail/INBOX/mails/new"
    assert_text "宛先"
    assert_text "件名"
    assert_selector "textarea[name='item[in_to]']"
    assert_selector "textarea[name='item[in_subject]']"
  end

  test "japanese characters render in the page title and navigation" do
    login_as_admin

    # 日本語の主要ラベルが文字化けせず表示される (ISO-2022-JP/UTF-8 経路の健全性)
    assert_text "受信トレイ"
    assert_text "送信トレイ"
    assert_text "ごみ箱"
  end
end
