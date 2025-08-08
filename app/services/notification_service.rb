class NotificationService
  class << self
    def deliver_sms(recipient, content, notification_type = nil)
      return unless recipient.sms_auth?

      notification = create_notification(
        recipient: recipient,
        content: content,
        delivery_method: :sms,
        notification_type: notification_type
      )

      send_sms(recipient, content)
      notification.mark_as_delivered!
      notification
    rescue => e
      Rails.logger.error "Failed to deliver SMS notification: #{e.message}"
      notification&.update(error_message: e.message) if notification
      raise
    end

    def deliver_email(recipient, subject, content, notification_type = nil)
      return unless recipient.email_auth?

      notification = create_notification(
        recipient: recipient,
        content: content,
        delivery_method: :email,
        notification_type: notification_type
      )

      send_email(recipient, subject, content)
      notification.mark_as_delivered!
      notification
    rescue => e
      Rails.logger.error "Failed to deliver email notification: #{e.message}"
      notification&.update(error_message: e.message) if notification
      raise
    end

    def deliver_multi_channel(recipient, sms_content: nil, email_subject: nil, email_content: nil, notification_type: nil)
      notifications = []

      if sms_content && recipient.sms_auth?
        notifications << deliver_sms(recipient, sms_content, notification_type)
      end

      if email_subject && email_content && recipient.email_auth?
        notifications << deliver_email(recipient, email_subject, email_content, notification_type)
      end

      notifications.compact
    end

    private

    def create_notification(recipient:, content:, delivery_method:, notification_type:)
      Notification.create!(
        recipient: recipient,
        content: content,
        delivery_method: delivery_method,
        notification_type: notification_type || "generic"
      )
    end

    def send_sms(recipient, content)
      client = Twilio::REST::Client.new(
        ENV["TWILIO_ACCOUNT_SID"],
        ENV["TWILIO_ACCOUNT_TOKEN"]
      )

      client.messages.create(
        from: ENV["TWILIO_PHONE_NUMBER"],
        to: recipient.phone_number,
        body: content
      )
    end

    def send_email(recipient, subject, content)
      ApplicationMailer.with(
        recipient: recipient,
        subject: subject,
        body: content
      ).notification_email.deliver_now
    end
  end
end
