# frozen_string_literal: true

class CreateGoodJobTables < ActiveRecord::Migration[8.1]
  def up
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :good_jobs, id: :uuid do |t|
      t.text :queue_name
      t.integer :priority
      t.jsonb :serialized_params
      t.datetime :scheduled_at
      t.datetime :performed_at
      t.datetime :finished_at
      t.text :error
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.uuid :active_job_id
      t.text :concurrency_key
      t.text :cron_key
      t.uuid :retried_good_job_id
      t.datetime :cron_at
      t.uuid :batch_id
      t.uuid :batch_callback_id
      t.boolean :is_discrete
      t.integer :executions_count
      t.text :job_class
      t.integer :error_event, limit: 2
      t.text :labels, array: true
      t.uuid :locked_by_id
      t.datetime :locked_at
    end

    add_index :good_jobs, :scheduled_at, where: "(finished_at IS NULL)", name: :index_good_jobs_on_scheduled_at
    add_index :good_jobs, [:queue_name, :scheduled_at], where: "(finished_at IS NULL)", name: :index_good_jobs_on_queue_name_scheduled_at
    add_index :good_jobs, :active_job_id, name: :index_good_jobs_on_active_job_id
    add_index :good_jobs, :cron_key, name: :index_good_jobs_on_cron_key

    create_table :good_job_processes, id: :uuid do |t|
      t.jsonb :state
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    create_table :good_job_settings, id: :uuid do |t|
      t.text :key
      t.jsonb :value
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :good_job_settings, :key, unique: true

    create_table :good_job_batches, id: :uuid do |t|
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.text :description
      t.jsonb :serialized_properties
      t.text :on_finish
      t.text :on_success
      t.text :on_discard
      t.text :callback_queue_name
      t.integer :callback_priority
      t.datetime :enqueued_at
      t.datetime :finished_at
      t.datetime :discarded_at
    end

    create_table :good_job_executions, id: :uuid do |t|
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.uuid :active_job_id, null: false
      t.text :job_class
      t.text :queue_name
      t.jsonb :serialized_params
      t.datetime :scheduled_at
      t.datetime :finished_at
      t.text :error
      t.integer :error_event, limit: 2
    end

    add_index :good_job_executions, :active_job_id, name: :index_good_job_executions_on_active_job_id
  end

  def down
    drop_table :good_job_executions, if_exists: true
    drop_table :good_job_batches, if_exists: true
    drop_table :good_job_settings, if_exists: true
    drop_table :good_job_processes, if_exists: true
    drop_table :good_jobs, if_exists: true
  end
end
