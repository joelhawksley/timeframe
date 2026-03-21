# frozen_string_literal: true

class AddCachedImageToDevices < ActiveRecord::Migration[8.0]
  def change
    add_column :devices, :cached_image, :text
    add_column :devices, :cached_image_at, :datetime
  end
end
