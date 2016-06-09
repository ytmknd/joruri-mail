class Gw::Admin::Webmail::MailAttachmentsController < ApplicationController#Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  protect_from_forgery except: [:create]
  before_action :check_tmp_id

  def index
    @items = Gw::WebmailMailAttachment.where(tmp_id: params[:tmp_id]).order(:id)
    _index @items
  end

  def show
    @item = Gw::WebmailMailAttachment.find_by!(id: params[:id], tmp_id: params[:tmp_id])
    return http_error(404) unless params[:filename] == @item.name

    send_data @item.read, type: @item.mime_type, disposition: @item.image_is == 1 ? 'inline' : 'attachment', filename: @item.name
  end

  def create
    raise "ファイルがアップロードされていません。" if params[:file].blank?

    cond = { tmp_id: params[:tmp_id] }

    total_size = params[:file].size
    Gw::WebmailMailAttachment.where(cond).each {|c| total_size += c.size.to_i }
    
    total_size_limit = params[:total_size_limit] || "5 MB"
    limit_value      = total_size_limit.gsub(/(.*?)[^0-9].*/, '\\1').to_i * (1024**2)

    if total_size > limit_value
      raise "容量制限を超えています。＜#{total_size_limit}＞"
    end

    item = Gw::WebmailMailAttachment.new(cond)
    begin
      rs = item.save_file(params[:file])
    rescue => e
      raise "ファイルの保存に失敗しました。#{e}"
    end
    raise item.errors.full_messages.join("\n") unless rs
    raise "ファイルが存在しません。(#{item.upload_path})" unless FileTest.file?(item.upload_path)

    render json: view_context.mail_attachment_view_model(item, tmp_id: params[:tmp_id], status: 'OK')
  rescue => e
    render json: { status: 'Error', message: e.to_s }
  end

  def destroy
    Gw::WebmailMailAttachment.where(id: params[:id], tmp_id: params[:tmp_id]).destroy_all

    render json: { status: 'OK' }
  end

  private

  def check_tmp_id
    return http_error(400) if params[:tmp_id].blank?
  end
end
