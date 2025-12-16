class AddLogRequestBodyToApiKeys < ActiveRecord::Migration[8.1]
  def change
    add_column :api_keys, :log_request_body, :boolean, default: true, null: false
  end
end
