# Monkeypatch ActiveStorage::Blob to add custom behavior

Rails.application.config.after_initialize do
  # Skip if we're precompiling assets, running database tasks, or if ActiveStorage isn't ready
  next if ENV["SECRET_KEY_BASE_DUMMY"]
  next if defined?(Rake) && Rake.respond_to?(:application) && Rake.application && Rake.application.top_level_tasks.any? { |task| task.start_with?("db:") }
  next unless defined?(ActiveStorage::Blob)
  next unless Rails.application.initialized?

  # Additional safety check - ensure we have a master key
  next unless Rails.application.credentials.config.present?

  module SetIdPatch
    extend ActiveSupport::Concern

    included do
      before_create :set_id_if_missing
    end

    private

    def set_id_if_missing
      self.id ||= SecureRandom.uuid
    end
  end

  # Include the patch in ActiveStorage::Blob
  ActiveStorage::Blob.include(SetIdPatch)
  ActiveStorage::Attachment.include(SetIdPatch)
  ActiveStorage::VariantRecord.include(SetIdPatch)
end
