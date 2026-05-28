class ApplicationController < ActionController::Base
  include Pagy::Backend
  helper_method :pagy_url_for

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern unless Rails.env.test?

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,   keys: [ :first_name, :last_name, :phone ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :phone ])
  end

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def authenticate_admin!
    unless current_user&.admin?
      redirect_to new_user_session_path, alert: "Debes iniciar sesión como administrador."
    end
  end
end
