class Notification < ApplicationRecord
  belongs_to :recipient, polymorphic: true

  validates :recipient, presence: true
  validates :notification_type, presence: true
  validates :content, presence: true
  validates :delivery_method, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(notification_type: type) }
  scope :by_delivery_method, ->(method) { where(delivery_method: method) }

  enum :delivery_method, {
    sms: 0,
    email: 1
  }

  def delivered?
    delivered_at.present?
  end

  def mark_as_delivered!
    update!(delivered_at: Time.current)
  end
end
