# encoding: utf-8
module Sys::Model::Rel::Publication
  def self.included(mod)
    mod.belongs_to :publisher, :foreign_key => 'unid', :class_name => 'Sys::Publisher',
      :dependent => :destroy
  end

  def public_status
    return published_at ? '公開中' : '非公開'
  end

  def public_path
    Page.site.public_path + public_uri
  end

  def public_uri
    '/'#TODO
  end

  def preview_uri(options = {})
    return nil unless public_uri
    site = options[:site] || Page.site
    "#{Core.full_uri}_preview/#{format('%08d', site.id)}#{public_uri}" 
  end

  def publish_uri(options = {})
    site = options[:site] || Page.site
    "#{Core.full_uri}_publish/#{format('%08d', site.id)}#{public_uri}" 
  end

  def publishable
    editable
    self.and "#{self.class.table_name}.state", 'recognized'
    return self
  end

  def closable
    editable
    public
    return self
  end

  def publishable?
    return false unless editable?
    return false unless recognized?
    return true
  end

  def rebuildable?
    return false unless editable?
    return state == 'public'# && published_at
  end

  def closable?
    return false unless editable?
    return state == 'public'# && published_at
  end

  def publish(content, options = {})
    return false unless content
    @save_mode = :publish
    
    self.state          = 'public'
    self.published_at ||= Core.now
    
    return false unless save(:validate => false)
    Util::File.put(public_path, :data => content, :mkdir => true)
    
    pub                = publisher || Sys::Publisher.new
    pub.published_at   = Core.now
    pub.published_path = public_path.gsub(/^#{Rails.root.to_s}/, '.')
    pub.name           = File.basename(public_path)
    pub.content_type   = 'text/html'
    pub.content_length = content.size
    if pub.id
      return false unless pub.save
    else
      pub.id         = unid
      pub.created_at = Core.now
      pub.updated_at = Core.now
      return false unless pub.save_with_direct_sql
    end
    publisher(true)
    
    return true
  end

  def rebuild(content, options = {})
    unless public?
      errors.add :base, "公開されていません。"
      return false
    end
    
    if publisher
      publisher.destroy
      publisher(true)
    end
    
    unless creator
      self.in_creator = {:user_id => '', :group_id => ''}
    end

    publish(content)
  end

  def close
    @save_mode = :close

    if publisher
      publisher.destroy
      publisher(true)
    end

    self.state = 'closed' if self.state == 'public'
    save(:validate => false)
  end
end