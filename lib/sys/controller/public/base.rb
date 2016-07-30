class Sys::Controller::Public::Base < ApplicationController
  before_action :pre_dispatch
  
  def pre_dispatch
    ## each processes before dispatch
  end
end
