class Invoice < ApplicationRecord
  belongs_to :user
  belongs_to :client
  has_many :invoice_items, dependent: :destroy

  enum :status, { draft: 0, sent: 1, paid: 2, overdue: 3, cancelled: 4 }

  validates :invoice_number, presence: true, uniqueness: { scope: :user_id }
  validates :issue_date, presence: true
  validates :due_date, presence: true
  validates :status, presence: true
  validates :tax_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :user, presence: true
  validates :client, presence: true

  validate :due_date_after_issue_date

  scope :for_user, ->(user) { where(user: user) }

  before_validation :set_defaults, on: :create
  before_validation :generate_invoice_number_if_blank

  # Virtual methods for calculated fields
  def subtotal
    invoice_items.sum(&:total)
  end

  def tax_amount
    subtotal * (tax_rate || 0)
  end

  def total_amount
    subtotal + tax_amount
  end

  private

  def due_date_after_issue_date
    return unless issue_date && due_date

    if due_date < issue_date
      errors.add(:due_date, "must be after issue date")
    end
  end

  def set_defaults
    self.issue_date ||= Date.current
    self.due_date ||= Date.current + 30.days
    self.tax_rate ||= 0.0
    self.status ||= :draft
    self.invoice_number ||= generate_invoice_number
  end

  def generate_invoice_number_if_blank
    return unless invoice_number.blank? && user.present?
    self.invoice_number = generate_invoice_number
  end

  def generate_invoice_number
    return "INV-TEMP-#{SecureRandom.hex(4).upcase}" unless user.present?
    
    # Generate a simple invoice number based on user ID and count
    user_invoice_count = user.invoices.where.not(id: id).count + 1
    "INV-#{user.id.upcase[0..7]}-#{user_invoice_count.to_s.rjust(4, '0')}"
  end
end