# frozen_string_literal: true

class AddMissingGoodJobIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # good_jobs indexes
    add_index :good_jobs, [:active_job_id, :created_at],
      name: :index_good_jobs_on_active_job_id_and_created_at,
      algorithm: :concurrently,
      if_not_exists: true

    add_index :good_jobs, :concurrency_key,
      where: "(finished_at IS NULL)",
      name: :index_good_jobs_on_concurrency_key_when_unfinished,
      algorithm: :concurrently,
      if_not_exists: true

    add_index :good_jobs, [:cron_key, :created_at],
      where: "(cron_key IS NOT NULL)",
      name: :index_good_jobs_on_cron_key_and_created_at_cond,
      algorithm: :concurrently,
      if_not_exists: true

    add_index :good_jobs, [:cron_key, :cron_at],
      where: "(cron_key IS NOT NULL)",
      unique: true,
      name: :index_good_jobs_on_cron_key_and_cron_at_cond,
      algorithm: :concurrently,
      if_not_exists: true

    add_index :good_jobs, [:finished_at],
      where: "retried_good_job_id IS NULL AND finished_at IS NOT NULL",
      name: :index_good_jobs_jobs_on_finished_at,
      algorithm: :concurrently,
      if_not_exists: true

    add_index :good_jobs, [:priority, :created_at],
      order: {priority: "DESC NULLS LAST", created_at: :asc},
      where: "finished_at IS NULL",
      name: :index_good_jobs_jobs_on_priority_created_at_when_unfinished,
      algorithm: :concurrently,
      if_not_exists: true

    add_index :good_jobs, [:priority, :created_at],
      order: {priority: "ASC NULLS LAST", created_at: :asc},
      where: "finished_at IS NULL",
      name: :index_good_job_jobs_for_candidate_lookup,
      algorithm: :concurrently,
      if_not_exists: true

    add_index :good_jobs, [:batch_id],
      where: "batch_id IS NOT NULL",
      algorithm: :concurrently,
      if_not_exists: true

    add_index :good_jobs, [:batch_callback_id],
      where: "batch_callback_id IS NOT NULL",
      algorithm: :concurrently,
      if_not_exists: true

    add_index :good_jobs, :labels,
      using: :gin,
      where: "(labels IS NOT NULL)",
      name: :index_good_jobs_on_labels,
      algorithm: :concurrently,
      if_not_exists: true

    add_index :good_jobs, [:priority, :scheduled_at],
      order: {priority: "ASC NULLS LAST", scheduled_at: :asc},
      where: "finished_at IS NULL AND locked_by_id IS NULL",
      name: :index_good_jobs_on_priority_scheduled_at_unfinished_unlocked,
      algorithm: :concurrently,
      if_not_exists: true

    add_index :good_jobs, :locked_by_id,
      where: "locked_by_id IS NOT NULL",
      name: :index_good_jobs_on_locked_by_id,
      algorithm: :concurrently,
      if_not_exists: true

    # good_job_executions indexes
    add_index :good_job_executions, [:active_job_id, :created_at],
      name: :index_good_job_executions_on_active_job_id_and_created_at,
      algorithm: :concurrently,
      if_not_exists: true

    add_index :good_job_executions, [:process_id, :created_at],
      name: :index_good_job_executions_on_process_id_and_created_at,
      algorithm: :concurrently,
      if_not_exists: true
  end
end
