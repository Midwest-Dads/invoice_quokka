class AddErrorMessageToNotifications < ActiveRecord::Migration[8.0]
  def change
    add_column :notifications, :error_message, :text
  end
end
