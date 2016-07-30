module Webmail::Controller::Admin::Mobile::Mail
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
      redirect_to action: :edit, id: params[:id]
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
      return redirect_to webmail_sys_addresses_path
    elsif params[:addPriAddress]
      add_mail_params_to_session.call
      return redirect_to webmail_address_groups_path
    end

    if params[:commit_send]
      flash[:commit_send] = params[:commit_send]
      [:in_to, :in_cc, :in_bcc, :in_subject].each do |t|
        flash[t] = params[:item][t]
      end
    end

    case params[:mobile][:action]
    when 'new', 'create'
      create
    when 'edit', 'update'
      update
    when 'answer'
      answer
    when 'forward'
      forward
    else
      create
    end
  end
end
