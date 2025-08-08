class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :notifications, as: :recipient, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :invoices, dependent: :destroy

  # Conditional setup based on authentication method
  if Rails.application.config.authentication_method == :email
    # Email authentication setup
    has_secure_password
    normalizes :email_address, with: ->(e) { e.strip.downcase }

    validates :email_address,
      presence: true,
      uniqueness: true,
      format: { with: URI::MailTo::EMAIL_REGEXP }

    validates :password,
      presence: true,
      length: { minimum: 8 },
      on: :create
  else
    # SMS authentication setup
    normalizes :phone_number, with: ->(phone) {
      digits = phone.gsub(/\D/, "")
      digits = "1#{digits}" unless digits.start_with?("1")
      "+#{digits}"
    }

    validates :phone_number,
      presence: true,
      uniqueness: true,
      format: { with: /\A\+1\d{10}\z/, message: "must be a valid US phone number" }
  end

  # Authentication method helpers
  def email_auth?
    Rails.application.config.authentication_method == :email
  end

  def sms_auth?
    Rails.application.config.authentication_method == :sms
  end

  # Class methods
  def self.email_auth?
    Rails.application.config.authentication_method == :email
  end

  def self.sms_auth?
    Rails.application.config.authentication_method == :sms
  end

  def self.authenticate_by(params)
    return nil unless email_auth?
    find_by(email_address: params[:email_address])&.authenticate(params[:password])
  end

  def self.find_or_create_by_phone(phone_number)
    return nil unless sms_auth?
    find_or_create_by(phone_number: phone_number)
  end

  def generate_password_reset_token
    # Generate a secure token for password reset
    Rails.application.message_verifier(:password_reset).generate(id)
  end

  def self.find_by_password_reset_token!(token)
    user_id = Rails.application.message_verifier(:password_reset).verify(token)
    find(user_id)
  end
end
