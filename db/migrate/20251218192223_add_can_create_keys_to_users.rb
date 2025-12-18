class AddCanCreateKeysToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :can_create_keys, :boolean, default: false, null: false
  end
end
