json.count @items.size
json.total @items.total_entries
json.items @items do |item|
  json.id item.id
  json.name item.name
  json.email item.email
end
