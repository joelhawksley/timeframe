class MakeValuesUnique < ActiveRecord::Migration[7.0]
  def change
    add_index :values, :key, unique: true
  end
end
