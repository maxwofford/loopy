class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string :hca_id, null: false
      t.string :email, null: false

      t.timestamps
    end
    add_index :users, :hca_id, unique: true
  end
end
