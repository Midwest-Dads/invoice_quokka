class ConvertToEmailAuth20250721184018 < ActiveRecord::Migration[8.0]
  def up
    # Clear all users as requested
    User.destroy_all
    
    # Remove SMS field if it exists
    if column_exists?(:users, :phone_number)
      remove_index :users, :phone_number if index_exists?(:users, :phone_number)
      remove_column :users, :phone_number
    end
    
    # Add email fields if they don't exist
    unless column_exists?(:users, :email_address)
      add_column :users, :email_address, :string, null: false
      add_index :users, :email_address, unique: true
    end
    
    unless column_exists?(:users, :password_digest)
      add_column :users, :password_digest, :string, null: false
    end
  end

  def down
    # Clear all users
    User.destroy_all
    
    # Remove email fields
    if column_exists?(:users, :email_address)
      remove_index :users, :email_address if index_exists?(:users, :email_address)
      remove_column :users, :email_address
    end
    
    if column_exists?(:users, :password_digest)
      remove_column :users, :password_digest
    end
    
    # Add SMS field
    unless column_exists?(:users, :phone_number)
      add_column :users, :phone_number, :string, null: false
      add_index :users, :phone_number, unique: true
    end
  end
end
