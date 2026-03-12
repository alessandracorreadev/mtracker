class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :birth_date])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :birth_date])
  end
end
