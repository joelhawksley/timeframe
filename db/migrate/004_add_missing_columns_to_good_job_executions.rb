# frozen_string_literal: true

class AddMissingColumnsToGoodJobExecutions < ActiveRecord::Migration[8.1]
  def change
    add_column :good_job_executions, :process_id, :uuid
    add_column :good_job_executions, :duration, :interval
    add_column :good_job_executions, :error_backtrace, :text, array: true
  end
end
