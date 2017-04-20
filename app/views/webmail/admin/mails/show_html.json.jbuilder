limit_size = data_uri_scheme_limit_size
inlines = @item.inline_contents(
  show_image: true,
  embed_image: limit_size > 0,
  embed_image_size_limit: limit_size
)

json.array! inlines do |inline|
  if inline.alternative? || inline.content_type == 'text/html'
    json.seqno inline.seqno
    json.html mail_autolink(inline.html_body)
  end
end
