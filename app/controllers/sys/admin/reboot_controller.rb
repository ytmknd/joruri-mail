class Sys::Admin::RebootController < Sys::Controller::Admin::Base
  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)
  end

  def index
    FileUtils.touch(Rails.root.join('tmp/restart.txt'))
    render plain: 'OK'
  end
end
