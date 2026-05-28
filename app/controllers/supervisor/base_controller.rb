module Supervisor
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :authenticate_supervisor!
    layout "supervisor"

    helper_method :current_period, :period_range

    private

    def current_period
      @current_period ||= params[:period] || "month"
    end

    def period_range
      case current_period
      when "today"  then Date.current..Date.current
      when "week"   then Date.current.beginning_of_week..Date.current.end_of_week
      when "month"  then Date.current.beginning_of_month..Date.current.end_of_month
      when "custom"
        from = params[:from].present? ? Date.parse(params[:from]) : Date.current.beginning_of_month
        to   = params[:to].present?   ? Date.parse(params[:to])   : Date.current
        from..to
      else
        Date.current.beginning_of_month..Date.current.end_of_month
      end
    end
  end
end
