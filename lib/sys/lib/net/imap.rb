module Sys::Lib::Net::Imap
  require 'net/imap'

  attr_accessor :uid, :mailbox, :flags, :rfc822, :size, :mail
  attr_accessor :x_mailbox, :x_real_uid

  def self.included(mod)
    mod.extend ClassMethods
  end

  def self.connect
    unless config = Joruri.config.imap_settings
      raise NameError, "undefined setting `imap_settings` for #{self}"
    end

    imap = nil
    begin
      username = Core.current_user.account
      password = Core.current_user.password
      Timeout.timeout(3) do
        imap = Net::IMAP.new(config[:address], config[:port], config[:usessl])
        imap.login(username, password)
      end
      return imap
    rescue Net::IMAP::ByeResponseError => e
      raise "IMAP: 接続に失敗 (ByeResponseError)"
    rescue Net::IMAP::NoResponseError => e
      raise "IMAP: 認証に失敗しました。アカウントとパスワードの設定を確認してください。" if e.message == 'Authentication failed.'
      raise "IMAP: 接続に失敗 (NoResponseError)"
    rescue OpenSSL::SSL::SSLError
      raise "IMAP: 接続に失敗 (SSLError)"
    rescue Errno::ETIMEDOUT => e
      raise "IMAP: 接続に失敗 (ETIMEOUT)"
    rescue Errno::ECONNRESET
      raise "IMAP: 接続に失敗 (ECONNRESET)"
    rescue Timeout::Error => e
      #raise "IMAP: 接続に失敗 (Timeout::Error)"
      raise Sys::Lib::Net::Imap::Error.new("メールサーバが混雑等の原因により遅延しているようです。しばらく時間をおいてからアクセスしてください。")
    rescue SocketError => e
      raise "IMAP: DNSエラー (SocketError)"
    rescue Exception => e
      raise "IMAP: エラー (#{e})"
    end
  end

  def imap
    Core.imap
  end

  def parse(msg)
    begin
      @mail   = Mail::Message.new(msg)
      @rfc822 = msg
    rescue => e
      @mail   = Mail::Message.new
      @mail.subject = "#Error: #{e}"
    end
    self
  end

  def flags
    @flags || []
  end

  def seen?
    flags.index(:Seen)
  end

  def unseen?
    !flags.index(:Seen)
  end

  def draft?
    flags.index(:Draft)
  end

  def answered?
    flags.index(:Answered)
  end

  def forwarded?
    flags.index('$Forwarded')
  end

  def starred?
    flags.index(:Flagged)
  end

  def notified?
    flags.index('$Notified')
  end

  def labeled?(label_id = "")
    flags.index("$label#{label_id}")
  end

  def labels
    labeled = []
    flags.each{|v| labeled << v.gsub(/^\$label([0-9]+)$/, '\1') if v =~ /^\$label[0-9]+$/}
    labeled.sort
  end

  def destroy(complete = false)
    imap.select(mailbox)
    if mailbox !~ /^Trash(\.|$)/ && !complete
      imap.create("Trash") unless imap.list("", "Trash")
      response = imap.uid_copy(uid, 'Trash') rescue nil
      return false if !response || response.name != "OK"
    end
    imap.uid_store(uid, "+FLAGS", [:Deleted])
    imap.expunge
    return true
  end

  def move(to_mailbox)
    return true if mailbox == to_mailbox

    next_uid = imap.status(to_mailbox, ["UIDNEXT"])["UIDNEXT"]

    imap.select(mailbox)
    response = imap.uid_copy(uid, to_mailbox) rescue nil
    return false if !response || response.name != "OK"
    imap.uid_store(uid, "+FLAGS", [:Deleted])
    imap.expunge

    imap.select(to_mailbox)
    imap.uid_search(["UID", next_uid], "utf-8")

    return true
  end

  module ClassMethods
    def imap
      Core.imap
    end

    def disconnect
      if Core.imap
        Core.imap.logout()
        Core.imap.disconnect()
      end
    end

    def status(mailbox, attr)
      Core.imap.status(mailbox, attr)
    end

    def find_by_uid(uid, params = {})
      return nil if uid !~ /^\d+$/

      select = params[:select] || 'INBOX'
      filter = params[:conditions] || []

      imap.examine(select)
      imap.uid_search(["UID", uid] + filter, "utf-8").each do |id|
        msg = imap.uid_fetch(id, ["FLAGS", "RFC822"])
        next if msg.size == 0
        item = self.new
        item.parse(msg.first.attr['RFC822'])
        item.uid     = uid.to_i
        item.mailbox = select
        item.flags   = msg.first.attr['FLAGS']
        return item
      end
      return nil
    end

    def find_uid(key, params = {})
      return find_by_uid(key, params) if key != :all ##

      mailbox = params[:select] || 'INBOX'
      filter  = params[:conditions] || []
      sort    = params[:sort]
      page    = params[:page]
      limit   = params[:limit]

      imap.select(mailbox)
      sort ? imap.uid_sort(sort, filter, "utf-8") : imap.uid_search(filter, "utf-8")
    end

    def find(key, params = {})
      return find_by_uid(key, params) if key != :all

      mailbox = params[:select] || 'INBOX'
      filter  = params[:conditions] || []
      sort    = params[:sort]
      page    = params[:page]
      limit   = params[:limit]

      imap.select(mailbox)
      uids  = (sort ? imap.uid_sort(sort, filter, "utf-8") : imap.uid_search(filter, "utf-8"))
      total = uids.size

      if limit
        page   = page.to_s =~ /^[0-9]+$/ ? page.to_i : 1
        limit  = limit.to_s =~ /^[1-9][0-9]*$/ ? limit.to_i : 30
        if uids.present?
          ## v1
          #uids   = uids.reverse
          offset = (page - 1) * limit
          uids   = uids.slice(offset, limit) || []
#          ## v2
#          lim2 = limit
#          if (offset = total - (page - 1) * lim2 - lim2) < 0
#            lim2   += offset
#            offset  = 0
#          end
#          uids   = uids.slice(offset, lim2).reverse
        end
      end
      uids_original = uids.dup

      items = limit.nil? ? [] : Sys::Lib::Net::Imap::MailPaginate.new
      temps = []
      fetch(uids, mailbox).each do |item|
        idx = uids_original.index(item.uid)
        idx ? items[idx] = item : temps << item
      end
      items.unshift(*temps)
      items.delete(nil)

      ## pagination
      items.make_pagination(page: page, per_page: limit, total: total) if limit
      return items
    end

    def fetch(uids, mailbox, options = {})
      items = options[:items] || []
      return items if uids.blank?

      imap.examine(mailbox)

      uids   = [uids] if uids.class == Fixnum
      fields = ["UID", "FLAGS", "RFC822.SIZE", "BODY.PEEK[HEADER.FIELDS (DATE FROM TO SUBJECT CONTENT-TYPE)]"]
      msgs   = imap.uid_fetch(uids, fields)
      msgs.each do |msg|
        item = self.new
        item.parse(msg.attr["BODY[HEADER.FIELDS (DATE FROM TO SUBJECT CONTENT-TYPE)]"])
        item.uid     = msg.attr["UID"].to_i
        item.mailbox = mailbox
        item.size    = msg.attr['RFC822.SIZE']
        item.flags   = msg.attr["FLAGS"]
        items << item
      end if msgs.present?
#      uids.each do |uid|
#        msgs = imap.uid_fetch(uid, fields)
#        msgs.each do |msg|
#          item = self.new
#          item.parse(msg.attr["BODY[HEADER.FIELDS (DATE FROM TO SUBJECT CONTENT-TYPE)]"])
#          item.uid     = uid
#          item.mailbox = mailbox
#          item.size    = msg.attr['RFC822.SIZE']
#          item.flags   = msg.attr["FLAGS"]
#          items << item
#        end if !msgs.blank?
#      end
      items
    end

    def move_all(from_mailbox, to_mailbox, uids)
      return 0 if from_mailbox == to_mailbox
      return 0 if uids.size == 0

      num = 0
      imap.select(from_mailbox) rescue return 0
      Util::Database.lock_by_name(Core.current_user.account) do
        res = imap.uid_copy(uids, to_mailbox) rescue nil
        return 0 if !res || res.name != "OK"
        num = imap.uid_store(uids, "+FLAGS", [:Deleted]).size rescue 0
      end
      imap.expunge
      num
    end

    def copy_all(from_mailbox, to_mailbox, uids)
      return 0 if uids.size == 0

      imap.select(from_mailbox)
      res = imap.uid_copy(uids, to_mailbox) rescue nil
      return 0 if !res || res.name != "OK"

      uids.size
    end

    def delete_all(mailbox, uids, complete = false)
      return 0 if uids.size == 0

      num = 0
      imap.select(mailbox) rescue return 0
      Util::Database.lock_by_name(Core.current_user.account) do
        if mailbox !~ /^Trash(\.|$)/ && mailbox !~ /^Star(\.|$)/ && !complete
          unless imap.list("", "Trash")
            res = imap.create("Trash")
            return 0 if res.name != "OK"
          end
          res = imap.uid_copy(uids, 'Trash') rescue nil
          return 0 if !res || res.name != "OK"
        end
        num = imap.uid_store(uids, "+FLAGS", [:Deleted]).size rescue 0
      end
      imap.expunge
      num
    end

    def seen_all(mailbox, uids)
      imap.select(mailbox) rescue return 0
      imap.uid_store(uids, "+FLAGS", [:Seen]).size rescue 0
    end

    def unseen_all(mailbox, uids)
      imap.select(mailbox) rescue return 0
      imap.uid_store(uids, "-FLAGS", [:Seen]).size rescue 0
    end

    def star_all(mailbox, uids)
      imap.select(mailbox) rescue return 0
      imap.uid_store(uids, "+FLAGS", [:Flagged]).size rescue 0
    end

    def unstar_all(mailbox, uids)
      imap.select(mailbox) rescue return 0
      imap.uid_store(uids, "-FLAGS", [:Flagged]).size rescue 0
    end
   
    def include_starred_uid?(mailbox, uids)
      imap.select(mailbox) rescue return 0
      starred_uids = imap.uid_search(['UID', uids, 'UNDELETED', 'FLAGGED'], 'utf-8')
      uids.inject(false){|result,x| result || starred_uids.include?(x)}
    end

    def label_all(mailbox, uids, label_id)
      imap.select(mailbox) rescue return 0
      imap.uid_store(uids, "+FLAGS", ["$label#{label_id}"]).size rescue 0
    end

    def unlabel_all(mailbox, uids, label_id = nil)
      labels = []
      if label_id
        labels << "$label#{label_id}"
      else
        (0..9).each{|label_id| labels << "$label#{label_id}"}
      end
      imap.select(mailbox) rescue return 0
      imap.uid_store(uids, "-FLAGS", labels).size rescue 0
    end
  end
end
