class CreateValues < ActiveRecord::Migration[7.0]
  def change
    create_table :values do |t|
      t.string :key, null: false
      t.jsonb :value, null: false, default: {}
      t.timestamps
    end
  end
end
