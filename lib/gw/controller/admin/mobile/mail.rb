module Gw::Controller::Admin::Mobile::Mail
  
  def mobile_manage
    if params[:mobile_move]
      move
    elsif params[:mobile_copy]
      params[:copy] = '1'
      move
    elsif params[:mobile_delete]
      delete
    elsif params[:mobile_seen]
      seen
    elsif params[:mobile_unseen]
      unseen
    elsif params[:mobile_edit]
      params[:item].delete(:ids) if params[:item][:ids]
      redirect_to edit_gw_webmail_mail_path(params[:mailbox], params[:id])
    elsif params[:mobile_resend]
      params[:item].delete(:ids) if params[:item][:ids]
      redirect_to resend_gw_webmail_mail_path(params[:mailbox], params[:id])
    end
  end

  def mobile_send
    
    add_mail_params_to_session = lambda do
      session[:mobile] = params[:mobile]
      [:to, :cc, :bcc].each do |t|
        session[:mobile][t] = params[:item]["in_#{t}".intern].split(/,/).each {|x| x.strip! }
      end
      [:subject, :body].each do |t|
        session[:mobile][t] = params[:item]["in_#{t}".intern]
      end
      [:tmp_id, :tmp_attachment_ids].each do |t|
        session[:mobile][t] = params[:item][t]
      end
    end
    
    if params[:addSysAddress]
      add_mail_params_to_session.call
      return redirect_to gw_webmail_sys_addresses_path
    elsif params[:addPriAddress]
      add_mail_params_to_session.call
      return redirect_to gw_webmail_address_groups_path
    end
    
    if params[:commit_send]
      flash[:commit_send] = params[:commit_send]
      [:in_to, :in_cc, :in_bcc, :in_subject].each do |t|
        flash[t] = params[:item][t]
      end
    end
    
    case params[:mobile][:action]
    when 'create'
      return create
    when 'update'
      return update
    when 'answer'
      return answer
    when 'forward'
      return forward
    when 'resend'
      return create
    end
    
    create
  end
  
end