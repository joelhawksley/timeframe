class CreateGoogleAccounts < ActiveRecord::Migration[5.1]
  def change
    create_table :google_accounts do |t|
      t.references :user, index: true
      t.jsonb :google_authorization, default: {}, null: false
      t.string :email, index: true, null: false
      t.timestamps
    end
  end
end
