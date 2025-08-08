class CreateClients < ActiveRecord::Migration[8.0]
  def change
    create_table :clients, id: :string do |t|
      t.string :name
      t.string :email
      t.text :address
      t.string :phone
      t.references :user, null: false, foreign_key: true, type: :string

      t.timestamps
    end
  end
end
