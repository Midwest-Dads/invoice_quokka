class Sms::SessionsController < ApplicationController
  def destroy
    terminate_session
    redirect_to root_path
  end
end
