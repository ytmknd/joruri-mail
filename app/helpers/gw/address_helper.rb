module Gw::AddressHelper
  def address_view_model(group_id = '', group_name = '', addresses = [], options = {})
    {
      group_id: group_id.to_s,
      group_name: group_name,
      sort_key: '',
      sort_order: '',
      checked: { to: false, cc: false, bcc: false },
      addresses: addresses.map { |addr|
        {
          id: addr.id,
          name: addr.name,
          kana: addr.kana,
          email: addr.email,
          sort_no: addr.sort_no,
          checked: { to: false, cc: false, bcc: false }
        }
      }
    }.merge(options)
  end
end
