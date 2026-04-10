# frozen_string_literal: true

class AddLockTypeToGoodJobProcesses < ActiveRecord::Migration[8.1]
  def change
    add_column :good_job_processes, :lock_type, :integer, limit: 2
  end
end
