class AddApiResponses < ActiveRecord::Migration[7.2]
  def change
    create_table :api_responses do |t|
      t.string :name, null: false, index: true
      t.json :response, null: false
      t.timestamps
    end
  end
end
