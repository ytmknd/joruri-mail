json.group_id @gid.to_s
json.group_name @gname
json.search params[:search].present?
json.sort_key ''
json.sort_order ''
json.checked do
  json.to false
  json.cc false
  json.bcc false
end
json.users @users do |user|
  json.id user.id
  json.name user.name
  json.kana user.kana
  json.email user.email
  json.sort_no user.sort_no
  json.official_position user.official_position
  json.group_name user.groups.first.try(:name)
  json.checked do
    json.to false
    json.cc false
    json.bcc false
  end
end
json.users_size @users.size
json.users_total_entries @users.total_entries
