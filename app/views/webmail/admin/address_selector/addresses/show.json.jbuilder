json.groups @groups do |group|
  json.id group.id
  json.name group.name
  json.has_children group.children.count > 0 || group.addresses.count > 0
end
json.items @items do |item|
  json.id item.id
  json.name item.name
  json.email item.email
end
