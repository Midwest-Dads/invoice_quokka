class Client < ApplicationRecord
  belongs_to :user
  has_many :invoices, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :user, presence: true

  scope :for_user, ->(user) { where(user: user) }

  def display_name
    name
  end
end