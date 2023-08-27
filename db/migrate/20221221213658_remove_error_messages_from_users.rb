class RemoveErrorMessagesFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :error_messages
  end
end
