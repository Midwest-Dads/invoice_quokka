class Api::V1::VerificationsController < Api::V1::BaseController
  allow_unauthenticated_access
  rate_limit to: 5, within: 1.hour, only: :create

  def create
    phone_number = normalize_phone_number(params[:phone_number])

    unless valid_phone_number?(phone_number)
      flash[:alert] = "Please enter a valid US phone number"
      return render_error(
        message: "Please enter a valid US phone number",
        errors: { phone_number: [ "Invalid format" ] }
      )
    end

    result = SmsVerificationService.send_verification(phone_number)

    if result.status == "pending"
      session[:verification_phone] = phone_number
      flash[:notice] = "Verification code sent!"
      render_success(
        message: "Verification code sent!",
        data: { redirect_to: "/verification/edit" }
      )
    else
      error_message = "Failed to send verification code. Please try again."
      flash[:alert] = error_message
      render_error(message: error_message)
    end
  end

  def update
    phone_number = session[:verification_phone]
    code = params[:code]

    unless phone_number
      flash[:alert] = "Verification session expired"
      return render_error(message: "Verification session expired")
    end

    result = SmsVerificationService.verify_code(phone_number, code)

    case result.status
    when "approved"
      user = User.find_or_create_by_phone(phone_number)
      start_new_session_for(user)
      session.delete(:verification_phone)

      flash[:notice] = "Successfully signed in!"
      render_success(
        message: "Successfully signed in!",
        data: { redirect_to: after_authentication_url }
      )
    else
      flash[:alert] = "Invalid verification code"
      render_error(
        message: "Invalid verification code",
        errors: { code: [ "Code is incorrect or expired" ] }
      )
    end
  end

  private

  def normalize_phone_number(phone)
    digits = phone.gsub(/\D/, "")
    digits = "1#{digits}" unless digits.start_with?("1")
    "+#{digits}"
  end

  def valid_phone_number?(phone)
    phone.match?(/\A\+1\d{10}\z/)
  end

  def after_authentication_url
    "/"
  end
end
