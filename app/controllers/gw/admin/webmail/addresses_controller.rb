require 'csv'
class Gw::Admin::Webmail::AddressesController < Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout "admin/gw/webmail"
  helper Gw::AddressHelper

  def pre_dispatch
    #return error_auth unless Core.user.has_auth?(:designer)
  end

  def index
    return render text: ''

##    item = Gw::WebmailAddress.readable.where(user_id: Core.user.id)
##    item = item.where(group_id: @parent.id) if @parent
##    @items = item.order(:kana, :id).paginate(page: params[:page], per_page: params[:limit])
##    _index @items
  end

  def show
    @item = Gw::WebmailAddress.find(params[:id])
    return error_auth unless @item.readable?

    @item.in_groups = @item.groups.map(&:id).join(",")

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
    flash[:mail_to] = "#{@item.name} <#{@item.email}>"
    redirect_to new_gw_webmail_mail_path('INBOX')
  end

  def import
    #do nothing
  end

  def candidate_import
    return redirect_to action: :import unless params[:import_file]

    require 'nkf'

    @success_items = []
    @error_items = []
    
    header = [
      :name, :kana, :email, :company_name, :company_kana,
      :official_position, :company_tel, :company_fax, :company_zip_code, :company_address,
      :tel, :fax, :zip_code, :address, :mobile_tel, :uri, :memo, :ok
    ]
  
    email_pattern = /\A[a-z0-9!#\$%&'\*\+\-\/=\?\^_`\{\|\}~\.]+@[a-z0-9\-\.]+\Z/i 

    make_csv_rec = lambda do |headers, data, ok|
      rec = []
      data[:ok] = (ok ? '1' : '')
      headers.each do |header|
        rec << data[header].to_s
      end
      rec
    end

    conv_data = lambda do |data|
      {
        name:              get_dispname(data),
        kana:              "",
        email:             "#{data['電子メール アドレス']}",
        company_name:      "#{data['会社名']}",
        company_kana:      "",
        official_position: "#{data['役職']}",
        company_tel:       "#{data['勤務先電話番号']}",
        company_fax:       "#{data['勤務先ファックス']}",
        company_zip_code:  "#{data['勤務先の郵便番号']}",
        company_address:   "#{data['勤務先の都道府県']}#{data['勤務先の市区町村']}#{data['勤務先の番地']}",
        tel:               "#{data['自宅電話番号 :']}",
        fax:               "#{data['自宅ファックス']}",
        zip_code:          "#{data['自宅の郵便番号']}",
        address:           "#{data['自宅の都道府県']}#{data['自宅の市区町村']}#{data['自宅の番地']}",
        mobile_tel:        "#{data['携帯電話 ']}",
        uri:               "#{data['個人 Web ページ']}",
        memo:              "#{data['メモ']}",
        ok:                ""
      }
    end

    check_data = lambda do |data|
      check = true
      #名前をチェック
      check &&= data[:name] != ""
      #メールアドレスをチェック
      check &&= data[:email].to_s.strip =~ email_pattern 
      check
    end

    make_item = lambda do |data|
      {
        name: data[0].to_s,
        email: data[2].to_s.strip,
      }
    end

    begin
      read_data = ""
      @csv = CSV.generate(encoding: 'utf-8') do |csv|
        csv << header
        read_data = NKF.nkf('-m0 -wx -Lu', params[:import_file].read)

        CSV.parse(read_data, headers: true) do |data|
          data = conv_data.call(data)
          check = check_data.call(data)
          csvline = make_csv_rec.call(header, data, check)

          item = make_item.call(csvline)
          if check
            @success_items << item
          else
            @error_items << item
          end

          csv << csvline
        end
      end
    rescue CSV::MalformedCSVError => e
      raise e
    rescue ArgumentError => e
      #error_log("#{e.class.name}: #{e.message} #{read_data}")
      raise e
    end
  end

  def exec_import
    return redirect_to action: :import unless params[:csv]
    
    @success_items = []
    @error_items = []

    make_item = lambda do |data|
      {
        name: data[:name],
        email: data[:email]
      }
    end

    CSV.parse(params[:csv], headers: true, header_converters: :symbol) do |data|
      unless data[:ok] == "1"
        @error_items << make_item.call(data)
        next
      end

      item = Gw::WebmailAddress.new
      item.user_id = Core.user.id
      item.name = data[:name]                           #名前
      item.kana = data[:kana]                           #ふりがな   
      item.email = data[:email]                         #メールアドレス
      item.company_name = data[:company_name]           #会社名
      item.company_kana = data[:company_kana]           #会社名カナ
      item.official_position = data[:official_position] #役職
      item.company_tel = data[:company_tel]             #会社TEL
      item.company_fax = data[:company_fax]             #会社FAX
      item.company_zip_code = data[:company_zip_code]   #会社郵便番号
      item.company_address = data[:company_address]     #会社住所
      item.tel = data[:tel]                             #自宅TEL
      item.fax = data[:fax]                             #自宅FAX
      item.zip_code = data[:zip_code]                   #自宅郵便番号
      item.address = data[:address]                     #自宅住所
      item.mobile_tel = data[:mobile_tel]               #携帯電話
      item.uri = data[:uri]                             #WebサイトURI      
      item.memo = data[:memo]                           #メモ

      if item.save
        @success_items << make_item.call(data)
      else
        @error_items << make_item.call(data)
      end
    end

    flash.now[:notice] = "インポートが終了しました"
  end

  def export
    return unless request.post?

    header = [
      '表示名', '電子メール アドレス', '自宅の郵便番号', '自宅の都道府県', '自宅の市区町村',
      '自宅の番地', '自宅電話番号 :', '自宅ファックス', '携帯電話 ', '個人 Web ページ',
      '勤務先の郵便番号', '勤務先の都道府県', '勤務先の市区町村', '勤務先の番地', '勤務先電話番号', '勤務先ファックス', '会社名', '役職', 'メモ'
    ]

    csv = CSV.generate(encoding: 'utf-8') do |csv|
      csv << header
      items = Gw::WebmailAddress.readable.where(user_id: Core.user.id).order(:id)
      items.each do |item|
        address = split_addr(item.address)
        company_address = split_addr(item.company_address)

        csvline = []
        csvline << item.name.to_s               #名前
        csvline << item.email.to_s              #メールアドレス
        csvline << item.zip_code.to_s           #自宅郵便番号
        csvline << address[0]                   #自宅住所(都道府県)
        csvline << address[1]                   #自宅住所(市区町村)
        csvline << address[2]                   #自宅住所(番地)
        csvline << item.tel.to_s                #自宅TEL
        csvline << item.fax.to_s                #自宅FAX
        csvline << item.mobile_tel.to_s         #携帯電話
        csvline << item.uri.to_s                #WebサイトURI      
        csvline << item.company_zip_code.to_s   #会社郵便番号
        csvline << company_address[0]           #会社住所(都道府県)
        csvline << company_address[1]           #会社住所(市区町村)
        csvline << company_address[2]           #会社住所(番地)
        csvline << item.company_tel.to_s        #会社TEL
        csvline << item.company_fax.to_s        #会社FAX
        csvline << item.company_name.to_s       #会社名
        csvline << item.official_position.to_s  #役職
        csvline << item.memo.to_s               #メモ
        csv << csvline 
      end
    end

    csv = NKF.nkf('-m0 -sx -Lw', csv)
    send_data(csv, type: 'text/csv', filename: "address_groups_#{Time.now.strftime("%Y%m%d_%H%M%S")}.csv" )
  end

  private

  def item_params
    params.require(:item).permit(:name, :kana, :sort_no, :email,
      :mobile_tel, :uri, :tel, :fax, :zip_code, :address, :company_name, :company_kana,
      :official_position, :company_tel, :company_fax, :company_zip_code, :company_address, :memo,
      :in_groups)
  end

  def split_addr(addr)
    addr = addr.to_s
    match = addr.scan(/(.+[都|道|府|県])(.+[市|区|町|村])(.*)/)
    return match[0] if match.length >= 1 && match[0].length == 3
    return [addr, '', '']
  end

  def get_dispname(data)
    disp = data['表示名'].to_s
    return disp if disp != ""
    names = [data['姓'].to_s, data['ミドル ネーム'].to_s, data['名'].to_s]
    return names.join(" ").strip
  end
end
