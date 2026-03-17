# frozen_string_literal: true

class CreateDevices < ActiveRecord::Migration[8.0]
  def change
    create_table :devices do |t|
      t.string :name, null: false
      t.string :model, null: false
      t.timestamps
    end
  end
end
