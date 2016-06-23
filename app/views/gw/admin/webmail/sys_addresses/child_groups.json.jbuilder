json.id @group.id
json.children @children do |child|
  json.id child.id
  json.name child.name
  json.has_children child.enabled_children.exists?
end
