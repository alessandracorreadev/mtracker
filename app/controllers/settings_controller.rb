class SettingsController < ApplicationController
  before_action :authenticate_user!
  layout "settings"

  def index
    redirect_to settings_theme_path
  end

  def theme
  end

  def password
  end

  def update_password
    if current_user.update_with_password(password_params)
      bypass_sign_in current_user
      redirect_to settings_password_path, notice: "Senha alterada com sucesso."
    else
      render :password, status: :unprocessable_entity
    end
  end

  def email
  end

  def update_email
    current_email = email_params[:current_email].to_s.strip
    if current_email.blank?
      current_user.errors.add(:current_email, "não pode ficar em branco")
      render :email, status: :unprocessable_entity
      return
    end
    if current_email.downcase != current_user.email.downcase
      current_user.errors.add(:current_email, "não confere com o email da conta")
      render :email, status: :unprocessable_entity
      return
    end
    if current_user.update_with_password(email_params)
      bypass_sign_in current_user
      redirect_to settings_email_path, notice: "Email atualizado com sucesso."
    else
      render :email, status: :unprocessable_entity
    end
  end

  def support
  end

  private

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end

  def email_params
    params.require(:user).permit(:current_email, :email, :current_password)
  end
end
