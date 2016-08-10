class Webmail::Admin::MailAttachmentsController < ApplicationController#Webmail::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  protect_from_forgery except: [:create]
  before_action :check_tmp_id

  def index
    @items = Webmail::MailAttachment.where(tmp_id: params[:tmp_id]).order(:id)
    _index @items
  end

  def show
    @item = Webmail::MailAttachment.find_by!(id: params[:id], tmp_id: params[:tmp_id])
    send_data @item.read, type: @item.mime_type, disposition: @item.image_is == 1 ? 'inline' : 'attachment', filename: @item.name
  end

  def create
    raise "ファイルがアップロードされていません。" if params[:file].blank?

    cond = { tmp_id: params[:tmp_id] }

    total_size = params[:file].size
    Webmail::MailAttachment.where(cond).each {|c| total_size += c.size.to_i }
    
    total_size_limit = Joruri.config.application['webmail.attachment_file_max_size']
    if total_size > total_size_limit * (1024**2)
      raise "容量制限を超えています。＜#{total_size_limit} MB＞"
    end

    item = Webmail::MailAttachment.new(cond)
    begin
      rs = item.save_file(params[:file])
    rescue => e
      raise "ファイルの保存に失敗しました。#{e}"
    end
    raise item.errors.full_messages.join("\n") unless rs
    raise "ファイルが存在しません。(#{item.upload_path})" unless FileTest.file?(item.upload_path)

    render plain: view_context.mail_attachment_view_model(item, tmp_id: params[:tmp_id], status: 'OK').to_json
  rescue => e
    render plain: { status: 'Error', message: e.to_s }.to_json
  end

  def destroy
    Webmail::MailAttachment.where(id: params[:id], tmp_id: params[:tmp_id]).destroy_all

    render json: { status: 'OK' }
  end

  private

  def check_tmp_id
    return http_error(400) if params[:tmp_id].blank?
  end
end
