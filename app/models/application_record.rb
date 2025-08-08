class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

before_create :generate_uuid

self.implicit_order_column = "created_at"

def generate_uuid
  self.id = SecureRandom.uuid
end
end
