class ErrorsController < ApplicationController
  # Skip authentication for error pages
  skip_before_action :authenticate_user!, raise: false

  def not_found
    render status: :not_found
  end

  def internal_server_error
    render status: :internal_server_error
  end
end
