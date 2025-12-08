class CreateApiRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :api_requests, id: :uuid do |t|
      t.references :api_key, null: false, foreign_key: true, type: :uuid
      t.string :endpoint, null: false
      t.jsonb :request_body, null: false, default: {}
      t.integer :response_status, null: false
      t.inet :ip_address, null: false
      t.jsonb :fingerprint, null: false, default: {}

      t.timestamps
    end

    add_index :api_requests, :created_at
    add_index :api_requests, :ip_address
  end
end
