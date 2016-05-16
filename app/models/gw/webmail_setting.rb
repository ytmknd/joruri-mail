class Gw::WebmailSetting < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Auth::Free
  
  class Category
    attr_accessor :name
    attr_accessor :title
    attr_reader :configs
    
    def initialize(name, title)
      @name = name.to_s
      @title = title
      @configs = []
    end    
  end

  @@config_categories = [
    ['メール一覧', :mail_list],
    ['メール読み取り', :mail_detail],
    ['メール送信', :mail_form],
    ['ラベル', :mail_label],
    [Joruri.config.application['webmail.sys_address_menu'], :sys_address],
    [Joruri.config.application['webmail.address_group_menu'], :address],
    ['携帯端末', :mobile]
  ]
  
  @@config_categorizing = {
    mail_list: [:mails_per_page, :mail_list_subject, :mail_list_from_address, :mail_address_history],
    mail_detail: [:mail_open_window, :html_mail_view, :mail_attachment_view],
    mail_form: [:mail_from, :mail_form_size, :sign_position, :mail_encoding],
    mail_label: [:label1, :label2, :label3, :label4, :label5, :label6, :label7, :label8, :label9],
    sys_address: [:sys_address_order],
    address: [:address_order],
    mobile: [:mobile_access, :mobile_password]
  }
  
  @@config_names = {
    mails_per_page: 'メール表示件数',
    mail_list_subject: '件名',
    mail_list_from_address: '差出人のメールアドレス',
    mail_address_history: 'クイックアドレス帳',
    html_mail_view: 'HTMLメールの表示',
    mail_attachment_view: '添付ファイルの表示',
    mail_open_window: 'メールの表示方法',
    mail_from: 'メール送信者名',
    mail_form_size: 'ウィンドウサイズ',
    mail_encoding: '文字エンコーディング',
    sign_position: '署名の位置（返信・転送時）',
    sys_address_order: '並び順',
    address_order: '並び順',
    mobile_access: 'モバイルアクセス',
    mobile_password: 'モバイルパスワード',
    label1: 'ラベル1',
    label2: 'ラベル2',
    label3: 'ラベル3',
    label4: 'ラベル4',
    label5: 'ラベル5',
    label6: 'ラベル6',
    label7: 'ラベル7',
    label8: 'ラベル8',
    label9: 'ラベル9'
  }
  
  @@config_input_types = {
    mails_per_page: :select,
    mail_list_subject: :select,
    mail_list_from_address: :select,
    mail_address_history: :select,
    html_mail_view: :select,
    mail_attachment_view: :select,
    mail_open_window: :select,
    mail_from: :select,
    mail_form_size: :select,
    mail_encoding: :select,
    sign_position: :select,
    sys_address_order: :select,
    address_order: :select,
    mobile_access: :select,
    mobile_password: :password_field,
    label1: :label_color_field,
    label2: :label_color_field,
    label3: :label_color_field,
    label4: :label_color_field,
    label5: :label_color_field,
    label6: :label_color_field,
    label7: :label_color_field,
    label8: :label_color_field,
    label9: :label_color_field
  }
  
  @@config_options = {
    mails_per_page: [['20件（標準）',''],['30件','30'],['40件','40'],['50件','50']],
    mail_list_subject: [['１行で表示（標準）', ''], ['折り返して表示', 'wrap']],
    mail_list_from_address: [['表示する（標準）', ''], ['表示しない', 'omit_address']],
    mail_address_history: [['表示しない', '0'], ['5件表示', '5'], ['10件表示（標準）', ''], ['15件表示', '15'], ['20件表示', '20']],
    html_mail_view: [['HTML形式で表示する（標準）', ''], ['テキスト形式で表示する', 'text']],
    mail_attachment_view: [['画像をサムネイル形式で表示する（標準）', ''], ['一覧形式で表示する', 'list']],
    mail_open_window: [['同じウィンドウで開く（標準）', ''], ['新しいウィンドウで開く', 'new_window']],
    mail_from: [['氏名（標準）',''],['メールアドレスのみ','only_address']],
    mail_form_size: [['小','small'],['中（標準）',''],['大','large']],
    mail_encoding: [['Unicode (UTF-8)','utf-8'],['日本語 (ISO-2022-JP)','']],
    sign_position: [['引用文の前（標準）', ''], ['引用文の後', 'bottom']],
    sys_address_order: [['メールアドレス（標準）', ''], ['名前', 'name'], ['フリガナ', 'kana'], ['役職（担当順）', 'sort_no']],
    address_order: [['メールアドレス（標準）', ''], ['フリガナ', 'kana'], ['並び順指定', 'sort_no']],
    mobile_access: [['不許可（標準）', '0'], ['許可', '1']],
    label1: { id: '1', name: '重要', color: '#ff0000', state: 'enabled'},
    label2: { id: '2', name: '未処理', color: '#ff007f', state: 'enabled'},
    label3: { id: '3', name: '作業中', color: '#4444ff', state: 'enabled'},
    label4: { id: '4', name: '作業終了', color: '#008f00', state: 'enabled'},
    label5: { id: '5', name: 'ToDo', color: '#8f8f00', state: 'enabled'},
    label6: { id: '6', name: 'その他1', color: '#8f3f00', state: 'enabled'},
    label7: { id: '7', name: 'その他2', color: '#008f8f', state: 'enabled'},
    label8: { id: '8', name: 'その他3', color: '#5f005f', state: 'enabled'},
    label9: { id: '9', name: 'その他4', color: '#777777', state: 'enabled'}
  }
  
  @@config_messages = {
    mobile_access: '<div style="color:red;">※パケット定額サービスに入っていない場合、高額の通信料が発生する場合があります。<br />' +
      '「許可」設定を行う場合は、この点をご理解のうえ、ご自身の責任で設定を行ってください。</div>'
  }
  
  @@switch_user_max_count = Joruri.config.application['webmail.switch_user_max_count']
  cattr_accessor :switch_user_max_count
  
  if @@switch_user_max_count > 0
    @@config_categories << ['切替ユーザー', :switch_user]
    
    @@config_categorizing[:switch_user] = []
    (1..@@switch_user_max_count).each do |i|
      @@config_categorizing[:switch_user] << "switch_user#{i}".intern
    end
    
    (1..@@switch_user_max_count).each do |i|
      @@config_names["switch_user#{i}".intern] = "切替ユーザー#{i}"
    end
    
    (1..@@switch_user_max_count).each do |i|
      @@config_input_types["switch_user#{i}".intern] = :account_password_field
    end
  end

  validates :user_id, :name, presence: true
  validates :value, inclusion: @@config_options[:address_order].map(&:last),
    if: lambda {|item| item.name == 'address_order' }
  validates :value, inclusion: @@config_options[:sys_address_order].map(&:last),
    if: lambda {|item| item.name == 'sys_address_order' }

  scope :readable, ->(user = Core.user) { where(user_id: user.id) }

  def self.user_config_categories
    categories = []
    @@config_categories.each do |name, title|
      categories << Category.new(name, title)
    end
    categories
  end

  def self.user_categorized_configs
    #load configs and save to hash
    tmp = {}
    self.where(user_id: Core.user.id).each do |conf|
      tmp[conf.name.intern] = conf
    end
    #categorize
    categories = []
    @@config_categories.each do |title, name|
      cat = Category.new(name, title)
      @@config_categorizing[name].each do |conf_name|
        conf = tmp[conf_name] || self.new(user_id: Core.user.id, name: conf_name.to_s, value: '')
        cat.configs << conf
      end
      categories << cat
    end
    categories
  end

  def self.user_configs
    @@config_names.map do |name, title|
      self.where(user_id: Core.user.id, name: name).first_or_initialize
    end
  end

  def self.user_config(name)
    self.where(user_id: Core.user.id, name: name).first_or_initialize(value: '')
  end

  def self.user_config_value(name, nullif = nil)
    if config = user_config(name)
      return config.value if config.value.present?
    end
    nullif
  end

  def self.user_config_values(names)
    self.where(user_id: Core.user.id, name: names).inject(HashWithIndifferentAccess.new) do |hash, conf|
      hash[conf.name] = conf.value
      hash
    end
  end

  def config_name
    @@config_names[self.name.intern]
  end

  def options
    @@config_options[self.name.intern]
  end

  def input_type
    @@config_input_types[self.name.intern]
  end

  def message
    @@config_messages[self.name.intern]
  end

  def value_name
    case input_type
    when :select
      options.each {|name, val| return name if value.to_s == val.to_s } if options
    when :text_field
      return value.blank? ? nil : value
    when :password_field
      return value.blank? ? nil : value.gsub(/./,"*")
    when :account_password_field
      return value.blank? ? nil : JSON.parse(value)['account']
    when :label_color_field
      return value.blank? ? options[:name] : JSON.parse(value)['name']
    end
    value.blank? ? nil : value
  end

  def set_value(params)
    case input_type
    when :account_password_field
      hash = {}
      if params[:account].present?
        hash[:account] = params[:account]
        hash[:password] = Util::String::Crypt.encrypt_with_mime(params[:password]) || ''
        self.value = hash.to_json
      else
        self.value = ''
      end
    when :label_color_field
      if params[:name].present? && params[:color].present?
        self.value = {
          id: params[:label_id],
          name: params[:name],
          color: params[:color],
          state: params[:state]
        }.to_json
      else
        self.value = ''
      end
    else
      self.value = params[:item][:value]
    end
  end

  def editable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  def deletable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  def initialize(attributes = nil)
    super
    if self.name
      case self.name.intern
      when :mobile_access
        self.value = Core.user.mobile_access.to_s
      when :mobile_password
        self.value = Core.user.mobile_password
      end
    end
    self
  end

  def save(*args)
    case name.intern
    when :mobile_access, :mobile_password
      user = Sys::User.find_by(id: Core.user.id)
      Gw::WebmailSetting.save_mobile_setting_for_user(user, self)
    else
      super(*args)
    end
  end

  def self.save_mobile_setting_for_user(user, item)
    return false unless user
    user[item.name.intern] = item.value
    unless ret = user.save
      user.errors.full_messages.to_a.each { |msg| item.errors.add(:base, msg) }
    end
    ret
  end

  def self.switch_user_count
    self.where(user_id: Core.user.id).where("name LIKE 'switch_user%'").count
  end

  def self.load_switch_user_confs
    names = []
    (1..@@switch_user_max_count).each{|idx| names << "switch_user#{idx}"}
    values = Gw::WebmailSetting.user_config_values(names)
    
    confs = []
    (1..@@switch_user_max_count).each do |idx|
      value = values["switch_user#{idx}"]
      if value.present?
        value = JSON.parse(value)
        confs << { account: value['account'], password: value['password'] } 
      end
    end
    confs
  end

  def self.load_switch_users
    users = [Core.user]
    confs = self.load_switch_user_confs
    confs.each do |conf|
      if user = Sys::User.find_by(account: conf[:account])
        user.password = Util::String::Crypt.decrypt_with_mime(conf[:password]) || ''
        users << user
      end
    end
    users
  end

  def self.load_label_confs
    names = []
    (1..9).each{|idx| names << "label#{idx}"}
    values = Gw::WebmailSetting.user_config_values(names)

    confs = []
    (1..9).each do |idx|
      value = values["label#{idx}"]
      if value.present?
        conf = JSON.parse(value) || {}
        conf.symbolize_keys!
        confs << conf if conf[:state] == 'enabled' 
      elsif conf = @@config_options["label#{idx}".intern]
        confs << conf if conf[:state] == 'enabled' && conf[:name].present?
      end
    end
    confs
  end
end
