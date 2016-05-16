require 'csv'
class Sys::Admin::SwitchUsersController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)
  end

  def index
  end

  def import
    if !params[:item] || !params[:item][:file]
      return redirect_to(action: :index)
    end

    require 'nkf'
    csv = NKF.nkf('-w', params[:item][:file].read)

    results = import_switch_users(csv)

    messages = []
    messages << "-- 追加 #{results[0]}件"
    messages << "-- 削除 #{results[1]}件" if results[1] != 0
    messages << "-- 失敗 #{results[2]}件" if results[2] != 0 

    flash[:notice] = "インポートが終了しました。<br />#{messages.join('<br />')}".html_safe
    return redirect_to(action: :index)
  end

  private

  def import_switch_users(csv)
    results = [0, 0, 0]
    switch_user_count = Gw::WebmailSetting.switch_user_max_count

    CSV.parse(csv, headers: true) do |data|
      account = data["ユーザID"]
      switch_user_account = []
      switch_user_password = []
      (0..switch_user_count).each do |i|
         switch_user_account << data["切替先#{i}ユーザID"]
         switch_user_password << data["切替先#{i}パスワード"]
      end

      if account.blank?
        results[2] += 1
        next
      end

      unless user = Sys::User.find_by(account: account)
        results[2] += 1
        next
      end

      Gw::WebmailSetting.where(user_id: user.id).where("name LIKE 'switch_user%'").delete_all

      saved_count = 0
      (0..switch_user_count).each do |i|
        next if switch_user_account[i].blank?

        hash = {}
        hash[:account] = switch_user_account[i]
        hash[:password] = Util::String::Crypt.encrypt_with_mime(switch_user_password[i]) || ''

        setting = Gw::WebmailSetting.new
        setting.user_id = user.id
        setting.name    = "switch_user#{i}"
        setting.value   = hash.to_json
        if setting.save
          saved_count += 1
        end
      end

      if saved_count > 0
        results[0] += 1
      else
        results[1] += 1
      end
    end

    results
  end
end
