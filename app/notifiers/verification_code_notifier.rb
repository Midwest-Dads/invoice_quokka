class VerificationCodeNotifier < BaseNotifier
  # Restrict to SMS delivery only
  sms_only

  private

  def message_content
    "Your verification code is: #{params[:code]}. This code expires in 10 minutes."
  end
end
