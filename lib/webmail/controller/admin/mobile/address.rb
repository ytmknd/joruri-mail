module Webmail::Controller::Admin::Mobile::Address
  extend ActiveSupport::Concern

  included do
    before_action :adjust_mobile_params
  end

  def mobile_manage
    if params[:createMail]
      return mobile_create_mail
    elsif params[:deleteAddress]
      mobile_delete_address
    elsif params[:selectAddress]
      mobile_select_address
    end
    redirect_to action: :index, group_id: params[:group_id]
  end

  private

  def adjust_mobile_params
    val = nil
    params.each do |k,v|
      if k =~ /^deleteAddress=/
        val = k
        break
      end
    end
    params[:deleteAddress] = val.sub(/^deleteAddress=/, '') if val
  end

  def mobile_create_mail
    session[:mobile] ||= {}
    [:to, :cc, :bcc].each do |t|
      session[:mobile][t] ||= []
      session[:mobile][t] += ids_to_addrs(params[t])
      flash["mail_#{t}".intern] = session[:mobile][t].uniq.join(', ')
    end
    [:subject, :body, :tmp_id, :tmp_attachment_ids].each do |t|
      flash["mail_#{t}".intern] = session[:mobile][t]
    end

    location = {
      controller: 'webmail/admin/mails',
      action: session[:mobile][:action] || 'new',
      mailbox: session[:mobile][:mailbox] || 'INBOX',
      id: session[:mobile][:uid],
      qt: session[:mobile][:qt] != "" ? session[:mobile][:qt] : nil 
    }

    session[:mobile] = nil

    redirect_to url_for(location)
  end

  def mobile_delete_address
    delete_address = lambda do
      strs = params[:deleteAddress].split('=')
      return false if strs.blank?
      strs = strs[0].split('_')
      return false if strs.length < 2
      session[:mobile][strs[0].intern].delete_at(strs[1].to_i)
      true
    end

    if delete_address.call
      flash[:notice] = "1件の選択済みアドレスを削除しました。"
    else
      flash[:notice] = "選択済みアドレスを削除できませんでした。"
    end
  end

  def mobile_select_address
    select_num = 0
    session[:mobile] ||= {}
    [:to, :cc, :bcc].each do |t|
      session[:mobile][t] ||= []
      before_num = session[:mobile][t].length
      session[:mobile][t] += ids_to_addrs(params[t])
      session[:mobile][t].uniq!
      select_num += (session[:mobile][t].length - before_num)
    end
    flash[:notice] = "#{select_num}件のアドレスを選択しました。"
  end
end
