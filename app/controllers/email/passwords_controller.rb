class Email::PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ show update ]

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      reset_url = url_for(controller: "email/passwords", action: "show", token: user.generate_password_reset_token)
      PasswordResetNotifier.with(reset_url: reset_url).deliver(user)
    end

    redirect_to new_session_path, notice: "Check your email for reset instructions"
  end

  def show
  end

  def update
    if @user.update(password_params)
      redirect_to new_session_path, notice: "Your password was reset successfully. Please sign in"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_password_reset_token!(params[:token])
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_password_path, alert: "That password reset link is invalid"
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
