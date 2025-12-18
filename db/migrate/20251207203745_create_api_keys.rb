class CreateApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :project, null: false
      t.string :key_hash, null: false
      t.string :scopes, array: true, default: [], null: false
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :api_keys, :key_hash, unique: true
    add_index :api_keys, [ :user_id, :project ]
  end
end
