# frozen_string_literal: true

class AddDisplayTemplateToDevices < ActiveRecord::Migration[8.1]
  def change
    add_column :devices, :display_template, :string, null: false, default: "default"
  end
end
