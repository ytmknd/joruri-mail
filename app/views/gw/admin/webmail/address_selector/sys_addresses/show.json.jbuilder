json.groups @groups do |group|
  json.id group.id
  json.name group.name
  json.has_children group.enabled_children.count > 0 || group.users_having_email.count > 0
end
json.items @items do |item|
  json.id item.id
  json.account item.account
  json.name item.name
  json.email item.email
end
