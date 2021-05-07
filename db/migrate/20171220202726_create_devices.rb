class CreateDevices < ActiveRecord::Migration[5.1]
  def change
    create_table :devices do |t|
      t.references :user, null: false, index: true
      t.string :uuid, null: false
      t.string :template, null: false
      t.integer :width, null: false
      t.integer :height, null: false
      t.binary :current_image, limit: 10.megabyte
    end
  end
end
