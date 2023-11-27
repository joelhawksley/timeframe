class DropValues < ActiveRecord::Migration[7.1]
  def change
    drop_table :values
  end
end
