class Api::V1::BaseController < ApplicationController
  before_action :set_default_response_format

  private

  def set_default_response_format
    request.format = :json
  end

  def render_success(data: {}, message: nil, status: :ok)
    render json: {
      # TODO(adenta) I don't like this pattern, so lets see if we don't need it
      # success: true,
      data: data,
      message: message
    }, status: status
  end

  def render_error(message:, errors: {}, status: :unprocessable_entity)
    render json: {
      # TODO(adenta) I don't like this pattern, so lets see if we don't need it
      # success: false,
      message: message,
      errors: errors
    }, status: status
  end
end
