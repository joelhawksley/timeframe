# frozen_string_literal: true

class AddErrorsToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :error_messages, :string, array: true, default: []
  end
end
