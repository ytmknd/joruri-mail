class Sys::Admin::AirController < ApplicationController
  include Sys::Controller::Admin::Auth

  protect_from_forgery except: [:old_login, :login]

  def old_login
    render text: "NG"
  end

  def login
    @admin_uri = params[:path] || '/_admin/gw/webmail/INBOX/mails'
    @admin_uri += '?mobile=top' if request.mobile?

    if params[:account] && params[:password]
      return air_token(params[:account], params[:password], params[:mobile_password])
    elsif params[:account] && params[:token]
      return air_login(params[:account], params[:token])
    end
    render text: "NG"
  end

  def air_token(account, password, mobile_password)
    if user = Sys::User.authenticate(account, password)
      if mobile_password && !user.authenticate_mobile_password(mobile_password)
        user = nil
      end
    end

    return render text: 'NG' unless user

    now   = Time.now
    token = Digest::MD5.hexdigest(now.to_f.to_s)
    enc_password = Base64.encode64(Util::String::Crypt.encrypt(password))

    user_tmp = Sys::User.find(user.id)
    user_tmp.air_login_id = "#{token} #{enc_password}"
    user_tmp.save(validate: false)

    render text: "OK #{token}"
  end

  def air_login(account, token)
    user = Sys::User.where(account: account)
      .where.not(air_login_id: nil)
      .where("air_login_id LIKE ?", "#{Sys::User.escape_like(token)} %").first
    return render text: "ログインに失敗しました。" unless user

    token, enc_password = user.air_login_id.split(/ /)

    user.air_login_id = nil
    user.save(validate: false)

    user.password = Util::String::Crypt.decrypt(Base64.decode64(enc_password))

    set_current_user(user)
    Sys::Session.delete_past_sessions_at_random

    if request.get?
      redirect_to @admin_uri
    end
  end
end
