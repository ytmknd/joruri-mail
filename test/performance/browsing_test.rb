require 'test_helper'

class BrowsingTest < ActionDispatch::IntegrationTest
  def test_homepage
    get '/'
    assert_response :redirect
  end

  def test_protected_page_sets_lax_login_referrer_cookie
    get '/webmail/INBOX/mails'

    assert_response :redirect
    cookies = Array(@response.headers['Set-Cookie']).join("\n")
    assert_match(/sys_login_referrer=.*samesite=lax/i, cookies)
    assert_match(/_session_id=.*httponly/i, cookies)
  end

  def test_login_rejects_external_return_uri
    get '/_admin/login', params: { uri: 'https://example.test/webmail' }

    assert_response :success
    assert_includes @response.body, 'value="/webmail/INBOX/mails"'
    refute_includes @response.body, 'example.test'
  end

  def test_login_keeps_local_return_uri
    get '/_admin/login', params: { uri: '/webmail/INBOX/mails?page=1' }

    assert_response :success
    assert_includes @response.body, 'value="/webmail/INBOX/mails?page=1"'
  end
end
