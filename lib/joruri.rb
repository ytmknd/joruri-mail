# encoding: utf-8
module Joruri
  def self.version
    "1.3.1"
  end
  
  def self.default_config
    { "application" => {
        "sys.login_footer"                       => "",
        "sys.mobile_footer"                      => "",
        "sys.session_expiration"                 => 24,
        "sys.session_expiration_for_mobile"      => 1,
        "sys.force_site"                         => "",
        "webmail.mailbox_quota_alert_rate"       => 0.85,
        "webmail.attachment_file_max_size"       => 5,
        "webmail.attachment_file_upload_method"  => "flash",
        "webmail.show_only_ldap_user"            => 1,
        "webmail.filter_condition_max_count"     => 100,
        "webmail.mail_address_history_max_count" => 100,
        "webmail.synchronize_mobile_setting"     => 0,
        "webmail.show_gw_schedule_link"          => 1,
        "webmail.mail_menu"                      => "メール",
        "webmail.mailbox_menu"                   => "フォルダ",
        "webmail.sys_address_menu"               => "組織アドレス帳",
        "webmail.address_group_menu"             => "個人アドレス帳",
        "webmail.filter_menu"                    => "フィルタ",
        "webmail.template_menu"                  => "テンプレート",
        "webmail.sign_menu"                      => "署名",
        "webmail.memo_menu"                      => "メモ",
        "webmail.tool_menu"                      => "ツール",
        "webmail.setting_menu"                   => "設定",
        "webmail.doc_menu"                       => "ヘルプ"
    }}
  end
  
  def self.config
    $joruri_config ||= {}
    Joruri::Config
  end
  
  class Joruri::Config
    def self.application
      config = Joruri.default_config["application"]
      file   = "#{Rails.root}/config/application.yml"
      if ::File.exist?(file)
        yml = YAML.load_file(file)
        yml.each do |mod, values|
          values.each do |key, value|
            config["#{mod}.#{key}"] = value unless value.nil?
          end if values
        end if yml
      end
      $joruri_config[:application] = config
    end
    
    def self.imap_settings
      $joruri_config[:imap_settings]
    end
    
    def self.imap_settings=(config)
      $joruri_config[:imap_settings] = config
    end
    
    def self.sso_settings
      $joruri_config[:sso_settings]
    end
    
    def self.sso_settings=(config)
      $joruri_config[:sso_settings] = config
    end
  end
end