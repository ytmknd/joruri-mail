## ---------------------------------------------------------
## gw/webmail

current_user = Sys::User.find(1)

Sys::User.order(:id).each do |user|
  Gw::WebmailAddress.create(
    :user_id => current_user.id,
    :name    => user.name,
    :email   => user.email
  )
end

Gw::WebmailTemplate.create(
  :user_id      => current_user.id,
  :name         => "テンプレート１",
  :to           => "",
  :body         => "○○市 ○○様\n",
  :default_flag => 1
)

Gw::WebmailSign.create(
  :user_id      => current_user.id,
  :name         => "署名１",
  :body         => ("="*40) + "\nジョールリ市 ○○部○○課\n○○ ○○\n#{current_user.email}\n" + ("="*40),
  :default_flag => 1
)

Gw::WebmailFilter.create(
  :user_id          => current_user.id,
  :state            => "enabled",
  :name             => "迷惑メール",
  :sort_no          => 1,
  :action           => "delete",
  :mailbox          => "",
  :conditions_chain => "and",
  :conditions_attributes => [
    :column       => "subject",
    :inclusion    => "<",
    :value        => "広告"
  ]
)

Gw::WebmailDoc.create(
  :state            => "public",
  :sort_no          => 1,
  :published_at     => Time.now,
  :title            => "Joruri Mailについて",
  :body             => %Q(<p>Joruri Mail is available under the GNU General Public License (GPL v3).</p><p><a title="http://www.joruri.org/" href="http://www.joruri.org/" target="_blank">http://www.joruri.org/</a></p>)
)

