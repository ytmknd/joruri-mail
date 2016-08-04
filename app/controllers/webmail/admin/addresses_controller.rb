require 'csv'
class Webmail::Admin::AddressesController < Webmail::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout 'admin/webmail/base'

  def pre_dispatch
    #return error_auth unless Core.user.has_auth?(:designer)
  end

  def index
    return render plain: ''
  end

  def show
    @item = Webmail::Address.find(params[:id])
    return error_auth unless @item.readable?

    _show @item
  end

  def new
    @item = Webmail::Address.new
  end

  def create
    @item = Webmail::Address.new(item_params)
    @item.user_id = Core.user.id
    _create(@item, location: webmail_address_groups_path)
  end

  def update
    @item = Webmail::Address.find(params[:id])
    return error_auth unless @item.editable?
    @item.attributes = item_params
    @item.user_id = Core.user.id

    _update(@item, location: webmail_address_groups_path)
  end

  def destroy
    @item = Webmail::Address.find(params[:id])
    return error_auth unless @item.deletable?
    _destroy(@item, location: webmail_address_groups_path)
  end

  def create_mail
    @item = Webmail::Address.find(params[:id])
    return error_auth unless @item.readable?
    flash[:mail_to] = @item.email_format
    redirect_to new_webmail_mail_path('INBOX')
  end

  def import
    #do nothing
  end

  def candidate_import
    return redirect_to(action: :import) unless params[:import_file]

    @csv = NKF.nkf('-m0 -wx -Lu', params[:import_file].read)

    begin
      items = Webmail::Address.from_csv(@csv)
    rescue CSV::MalformedCSVError => e
      flash[:error] = "CSVフォーマットが不正です。（#{e}）"
      return redirect_to(action: :import)
    end
 
    @success_items, @error_items = items.partition(&:valid?)
  end

  def exec_import
    return redirect_to(action: :import) unless params[:csv]

    begin
      items = Webmail::Address.from_csv(params[:csv])
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

    items = Webmail::Address.readable.where(user_id: Core.user.id).order(:id)
    csv = Webmail::Address.to_csv(items)
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
