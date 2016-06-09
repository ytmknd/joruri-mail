class Gw::WebmailFilterCondition < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Auth::Free

  belongs_to :filter, foreign_key: :filter_id, class_name: 'Gw::WebmailFilter'

  validates :user_id, :column, :inclusion, :value, presence: true
  validate :validate_regexp

  scope :readable, ->(user = Core.user) { where(user_id: user.id) }

  def editable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  def deletable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  def column_options
    [["件名（Subject）","subject"],["差出人（From）","from"],["宛先（To）","to"]]
  end

  def column_label
    column_options.each {|c| return c[0] if column == c[1].to_s }
    nil
  end

  def inclusion_options
    [["に次を含む","<"],["に次を含まない","!<"],["が次と一致する","=="],["正規表現","=~"]]
  end

  def inclusion_label
    inclusion_options.each {|c| return c[0] if inclusion == c[1].to_s }
    nil
  end

  private

  def validate_regexp
    if inclusion == '=~' && value.present?
      begin
        Regexp.new(value)
      rescue => e
        errors.add(:value, "を正しく入力してください。（正規表現　/#{value}/, #{e}）")
      end
    end
  end
end
