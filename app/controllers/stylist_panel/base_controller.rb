module StylistPanel
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :authenticate_staff!
    layout "stylist_panel"
  end
end
