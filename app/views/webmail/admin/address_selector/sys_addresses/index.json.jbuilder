json.count @items.size
json.total @items.total_entries
json.items @items do |item|
  json.id item.id
  json.account item.account
  json.name item.name
  json.email item.email
  json.group_name item.groups.first.try(:name)
end
