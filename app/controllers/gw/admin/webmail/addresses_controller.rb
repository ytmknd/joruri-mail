require 'csv'
class Gw::Admin::Webmail::AddressesController < Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout "admin/gw/webmail"

  def pre_dispatch
    #return error_auth unless Core.user.has_auth?(:designer)
  end

  def index
    return render text: ''
  end

  def show
    @item = Gw::WebmailAddress.find(params[:id])
    return error_auth unless @item.readable?

    _show @item
  end

  def new
    @item = Gw::WebmailAddress.new
  end

  def create
    @item = Gw::WebmailAddress.new(item_params)
    @item.user_id = Core.user.id
    _create(@item, location: gw_webmail_address_groups_path)
  end

  def update
    @item = Gw::WebmailAddress.find(params[:id])
    return error_auth unless @item.editable?
    @item.attributes = item_params
    @item.user_id = Core.user.id

    _update(@item, location: gw_webmail_address_groups_path)
  end

  def destroy
    @item = Gw::WebmailAddress.find(params[:id])
    return error_auth unless @item.deletable?
    _destroy(@item, location: gw_webmail_address_groups_path)
  end

  def create_mail
    @item = Gw::WebmailAddress.find(params[:id])
    return error_auth unless @item.readable?
    flash[:mail_to] = @item.email_format
    redirect_to new_gw_webmail_mail_path('INBOX')
  end

  def import
    #do nothing
  end

  def candidate_import
    return redirect_to(action: :import) unless params[:import_file]

    @csv = NKF.nkf('-m0 -wx -Lu', params[:import_file].read)

    begin
      items = Gw::WebmailAddress.from_csv(@csv)
    rescue CSV::MalformedCSVError => e
      flash[:error] = "CSVフォーマットが不正です。（#{e}）"
      return redirect_to(action: :import)
    end
 
    @success_items, @error_items = items.partition(&:valid?)
  end

  def exec_import
    return redirect_to(action: :import) unless params[:csv]

    begin
      items = Gw::WebmailAddress.from_csv(params[:csv])
    rescue CSV::MalformedCSVError => e
      flash[:error] = "CSVフォーマットが不正です。（#{e}）"
      return redirect_to(action: :import)
    end

    items.each(&:save)
    @success_items, @error_items = items.partition(&:persisted?)

    flash.now[:notice] = "インポートが終了しました"
  end

  def export
    return unless request.post?

    items = Gw::WebmailAddress.readable.where(user_id: Core.user.id).order(:id)
    csv = Gw::WebmailAddress.to_csv(items)
    csv = NKF.nkf('-m0 -sx -Lw', csv)
    send_data(csv, type: 'text/csv', filename: "address_groups_#{Time.now.strftime("%Y%m%d_%H%M%S")}.csv" )
  end

  private

  def item_params
    params.require(:item).permit(:name, :kana, :sort_no, :email,
      :mobile_tel, :uri, :tel, :fax, :zip_code, :address, :company_name, :company_kana,
      :official_position, :company_tel, :company_fax, :company_zip_code, :company_address, :memo,
      :easy_entry, :group_ids => [])
  end
end
