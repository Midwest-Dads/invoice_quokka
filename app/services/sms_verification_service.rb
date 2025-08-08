class SmsVerificationService
  VERIFICATION_CODE_EXPIRY = 10.minutes
  MAX_ATTEMPTS_PER_PHONE = 3
  ATTEMPT_WINDOW = 1.hour

  class << self
    def send_verification(phone_number)
      Rails.logger.info "Sending verification SMS to: #{phone_number}"

      # Check rate limiting per phone number
      if exceeded_attempt_limit?(phone_number)
        Rails.logger.warn "Rate limit exceeded for phone: #{phone_number}"
        return OpenStruct.new(status: "failed", error: "Too many attempts. Please try again later.")
      end

      # Generate and store verification code
      verification_code = generate_verification_code
      store_verification_code(phone_number, verification_code)
      increment_attempt_count(phone_number)

      # Find or create user and send notification via unified system
      user = User.find_or_create_by_phone(phone_number)
      VerificationCodeNotifier.with(code: verification_code).deliver(user)

      Rails.logger.info "SMS sent successfully via unified notification system"
      OpenStruct.new(status: "pending")

    rescue => e
      Rails.logger.error "Error sending verification: #{e.message}"
      OpenStruct.new(status: "failed", error: "Service temporarily unavailable.")
    end

    def verify_code(phone_number, code)
      Rails.logger.info "Verifying code for: #{phone_number}"

      stored_code = retrieve_verification_code(phone_number)

      unless stored_code
        Rails.logger.info "No verification code found for: #{phone_number}"
        return OpenStruct.new(status: "failed", error: "Verification session expired")
      end

      if stored_code == code.to_i
        Rails.logger.info "Verification successful for: #{phone_number}"
        clear_verification_data(phone_number)
        OpenStruct.new(status: "approved")
      else
        Rails.logger.info "Invalid verification code for: #{phone_number}"
        OpenStruct.new(status: "failed", error: "Invalid verification code")
      end

    rescue => e
      Rails.logger.error "Error verifying code: #{e.message}"
      OpenStruct.new(status: "failed", error: "Verification failed")
    end

    private

    def generate_verification_code
      SecureRandom.random_number(900000) + 100000 # 6-digit code
    end

    def store_verification_code(phone_number, code)
      cache_key = verification_cache_key(phone_number)
      Rails.cache.write(cache_key, code, expires_in: VERIFICATION_CODE_EXPIRY)
    end

    def retrieve_verification_code(phone_number)
      cache_key = verification_cache_key(phone_number)
      Rails.cache.read(cache_key)
    end

    def clear_verification_data(phone_number)
      # Clear verification code
      verification_key = verification_cache_key(phone_number)
      Rails.cache.delete(verification_key)

      # Clear attempt count
      attempt_key = attempt_cache_key(phone_number)
      Rails.cache.delete(attempt_key)
    end

    def exceeded_attempt_limit?(phone_number)
      attempt_key = attempt_cache_key(phone_number)
      current_attempts = Rails.cache.read(attempt_key) || 0
      current_attempts >= MAX_ATTEMPTS_PER_PHONE
    end

    def increment_attempt_count(phone_number)
      attempt_key = attempt_cache_key(phone_number)
      current_attempts = Rails.cache.read(attempt_key) || 0
      Rails.cache.write(attempt_key, current_attempts + 1, expires_in: ATTEMPT_WINDOW)
    end

    def verification_cache_key(phone_number)
      "sms_verification:#{Digest::SHA256.hexdigest(phone_number)}"
    end

    def attempt_cache_key(phone_number)
      "sms_attempts:#{Digest::SHA256.hexdigest(phone_number)}"
    end
  end
end
