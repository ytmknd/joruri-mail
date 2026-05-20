require "application_system_test_case"

class AdminLoginTest < ApplicationSystemTestCase
  test "admin can log in and reach the inbox" do
    visit "/_admin/login"
    assert_selector "h1", text: "Joruri"

    fill_in "account",  with: "admin"
    fill_in "password", with: "admin"
    find("input[name=commit]").click

    # After login the user lands on the webmail inbox.
    assert_current_path(/\/webmail\//)
    assert_text "受信トレイ"
    assert_text "admin@demo.joruri.org"
  end

  test "wrong password keeps the user on the login page" do
    visit "/_admin/login"
    fill_in "account",  with: "admin"
    fill_in "password", with: "wrong-password"
    find("input[name=commit]").click

    assert_current_path("/_admin/login")
    # Full-width katakana in the actual error message
    assert_text "ユーザーＩＤ・パスワードを正しく入力してください"
  end
end
