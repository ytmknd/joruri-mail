children_counts = @group.enabled_children.enabled_children_counts
users_counts = @group.enabled_children.enabled_users_counts
json.groups @group.enabled_children do |group|
  json.id group.id
  json.name group.name
  json.has_children children_counts[group.id].to_i > 0 || users_counts[group.id].to_i > 0
end
json.items @items do |item|
  json.id item.id
  json.account item.account
  json.name item.name
  json.email item.email
end
