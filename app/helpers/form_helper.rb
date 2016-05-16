module FormHelper

  ## tinyMCE
  def init_tiny_mce(options = {})
    settings = []
    options.each do |k, v|
      v = %Q("#{v}") if v.class == String
      settings << "#{k}:#{v}"
    end
    [
      javascript_include_tag("/_common/js/tiny_mce/tiny_mce.js"),
      javascript_include_tag("/_common/js/tiny_mce/init.js"),
      javascript_tag("initTinyMCE({#{settings.join(',')}});")
    ].join("\n")
  end

  def submission_label(name)
    {
      add:       '追加する',
      create:    '作成する',
      register:  '登録する',
      edit:      '編集する',
      update:    '更新する',
      change:    '変更する',
      delete:    '削除する'
    }[name]
  end

  def submit(*args)
    make_tag = Proc.new do |_name, _label|
      _label ||= submission_label(_name) || _name.to_s.humanize
      submit_tag(_label, name: "commit_#{_name}", class: _name)
    end

    h = '<div class="submitters">'
    if args[0].class == String || args[0].class == Symbol
      h += make_tag.call(args[0], args[1])
    elsif args[0].class == Hash
      args[0].each {|k, v| h += make_tag.call(k, v) }
    elsif args[0].class == Array
      args[0].each {|v, k| h += make_tag.call(k, v) }
    end
    h += '</div>'
  end
end
