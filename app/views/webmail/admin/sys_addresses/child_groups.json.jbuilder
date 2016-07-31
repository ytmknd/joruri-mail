counts = @group.enabled_children.enabled_children_counts
json.id @group.id
json.children @group.enabled_children do |child|
  json.id child.id
  json.name child.name
  json.has_children counts[child.id].to_i > 0
end
