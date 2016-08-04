class Webmail::FilterCondition < ApplicationRecord
  include Sys::Model::Base
  include Sys::Model::Auth::Free

  belongs_to :filter, foreign_key: :filter_id, class_name: 'Webmail::Filter'

  validates :user_id, :column, :inclusion, :value, presence: true
  validates :value, regexp: true, if: "inclusion == '=~'"

  scope :readable, ->(user = Core.user) { where(user_id: user.id) }

  enumerize :column, in: [:subject, :from, :to]
  enumerize :inclusion, in: ['<', '!<', '==', '=~']

  def editable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  def deletable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  def match?(data = {})
    texts = data[column.to_sym].to_a

    case inclusion
    when '<'
      texts.any? { |text| !( text =~ /#{Regexp.quote(value)}/i ).nil? }
    when '!<'
      texts.any? { |text| ( text =~ /#{Regexp.quote(value)}/i ).nil? }
    when '=='
      texts.any? { |text| text == value }
    when '=~'
      texts.any? { |text| ( text =~ /#{value}/im ) }
    else
      false
    end
  end
end
