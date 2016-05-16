class Sys::Base::Status < ActiveYaml::Base
  set_root_path Rails.root.join('config/modules/sys/enums')
  set_filename "status"
end
