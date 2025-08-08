class PasswordResetNotifier < BaseNotifier
  # Restrict to email delivery only
  email_only

  private

  def email_subject
    "Password Reset Request"
  end

  def message_content
    "Reset your password using this link: #{params[:reset_url]}"
  end
end
