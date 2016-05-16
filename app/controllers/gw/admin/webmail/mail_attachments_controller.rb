class Gw::Admin::Webmail::MailAttachmentsController < ApplicationController#Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  protect_from_forgery except: [:create]
  before_action :cookie_only_off

  ## need tmp_id
  def index
    return http_error(404) if params[:tmp_id].blank?

    files = Gw::WebmailMailAttachment.where(tmp_id: params[:tmp_id]).map do |f|
      {
        id:   f.id,
        name: f.name,
        size: f.size,
        eng_unit: f.eng_unit,
        image_is: f.image_is
      }
    end

    respond_to do |format|
      format.html { render :text => "" }
      format.xml  { render :xml => files.to_xml(:children => "item", :root => "items", :dasherize => false, :skip_types => true) }
    end
  end

  def show
    return http_error(404) if params[:tmp_id].blank?

    @file = Gw::WebmailMailAttachment.where(id: params[:id], tmp_id: params[:tmp_id]).first
    return http_error(404) unless @file
    return http_error(404) unless params[:filename] == @file.name

    filename = convert_to_download_filename(@file.name)

    send_data @file.read, type: @file.mime_type, disposition: @file.image_is == 1 ? 'inline' : 'attachment', filename: filename
  end

  def create
    raise "送信パラメータが不正です。" if params[:tmp_id].blank?
    raise "ファイルがアップロードされていません。" if params[:file].blank?

    cond = { tmp_id: params[:tmp_id] }

    total_size = params[:file].size
    Gw::WebmailMailAttachment.where(cond).each {|c| total_size += c.size.to_i }
    
    total_size_limit = params[:total_size_limit] || "5 MB"
    limit_value      = total_size_limit.gsub(/(.*?)[^0-9].*/, '\\1').to_i * (1024**2)

    if total_size > limit_value
      raise "容量制限を超えています。＜#{total_size_limit}＞"
    end

    file = Gw::WebmailMailAttachment.new(cond)
    begin
      rs = file.save_file(params[:file])
    rescue => e
      raise "ファイルの保存に失敗しました。#{e}"
    end
    raise file.errors.full_messages.join("\n") unless rs

    raise "ファイルが存在しません。(#{file.upload_path})" unless FileTest.file?(file.upload_path)

    ## garbage collect
    Sys::File.garbage_collect if rand(100) == 0

    return render text: "OK #{file.id} #{file.name} #{file.eng_unit} #{file.image_is}"
  rescue => e
    render text: "Error #{e}"
  end

  def destroy
    raise "送信パラメータが不正です。" if params[:tmp_id].blank?

    Gw::WebmailMailAttachment.where(id: params[:id], tmp_id: params[:tmp_id]).destroy_all

    render text: "OK #{params[:id]}"
  rescue => e
    return http_error(404)
  end

  private

  def cookie_only_off
    request.session_options[:cookie_only] = false
    request.session_options[:only]        = :create
  end
end
