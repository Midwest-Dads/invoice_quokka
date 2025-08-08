class Sms::VerificationsController < ApplicationController
  allow_unauthenticated_access

  def new
    # Mount PhoneInput React component
  end

  def edit
    # Redirect if no verification session
    redirect_to new_verification_path unless session[:verification_phone]
    # Mount OtpInput React component
  end
end
