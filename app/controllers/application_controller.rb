class ApplicationController < ActionController::Base
  before_action :authenticate_user!, unless: :devise_controller?

  protected

  def devise_controller?
    controller_path.start_with?("devise/")
  end

  def after_sign_in_path_for(_resource_or_scope)
    dashboard_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :birth_date])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :birth_date])
  end
end
