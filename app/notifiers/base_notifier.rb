class BaseNotifier
  attr_reader :params, :recipients

  def self.with(params = {})
    new(params)
  end

  def initialize(params = {})
    @params = params
  end

  def deliver(recipients)
    @recipients = Array(recipients)
    @recipients.each do |recipient|
      deliver_to_recipient(recipient)
    end
  end

  private

  def deliver_to_recipient(recipient)
    if sms_only?
      deliver_sms_to(recipient)
    elsif email_only?
      deliver_email_to(recipient)
    else
      # Multi-channel delivery
      NotificationService.deliver_multi_channel(
        recipient,
        sms_content: sms_content,
        email_subject: email_subject,
        email_content: email_content,
        notification_type: notification_type
      )
    end
  end

  def deliver_sms_to(recipient)
    return unless sms_content

    NotificationService.deliver_sms(
      recipient,
      sms_content,
      notification_type
    )
  end

  def deliver_email_to(recipient)
    return unless email_subject && email_content

    NotificationService.deliver_email(
      recipient,
      email_subject,
      email_content,
      notification_type
    )
  end

  # Override these methods in subclasses
  def sms_content
    message_content
  end

  def email_content
    message_content
  end

  def email_subject
    "Notification"
  end

  def message_content
    raise NotImplementedError, "Subclasses must implement message_content"
  end

  def notification_type
    self.class.name.underscore.gsub("_notifier", "")
  end

  # Delivery method restrictions (override in subclasses)
  def sms_only?
    self.class.instance_variable_get(:@sms_only) || false
  end

  def email_only?
    self.class.instance_variable_get(:@email_only) || false
  end

  # Class methods for delivery restrictions
  class << self
    def sms_only
      @sms_only = true
      @email_only = false
    end

    def email_only
      @email_only = true
      @sms_only = false
    end

    def multi_channel
      @sms_only = false
      @email_only = false
    end
  end
end
