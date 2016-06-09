module Gw::SysAddressHelper
  def sys_address_view_model(group_id = '', group_name = '', users = [], options = {})
    {
      group_id: group_id.to_s,
      group_name: group_name,
      search: false,
      sort_key: '',
      sort_order: '',
      checked: { to: false, cc: false, bcc: false },
      users: users.map { |user|
        {
          id: user.id,
          name: user.name,
          kana: user.kana,
          email: user.email,
          sort_no: user.sort_no,
          official_position: user.official_position,
          group_name: user.groups.first.try(:name),
          checked: { to: false, cc: false, bcc: false },
        }
      },
      users_size: users.size,
      users_total_entries: users.total_entries,
    }.merge(options)
  end
end
