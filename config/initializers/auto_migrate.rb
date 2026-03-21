# frozen_string_literal: true

# :nocov:
# Automatically run pending migrations on boot.
# This ensures Home Assistant add-on consumers get schema updates
# when they upgrade Timeframe without needing to run CLI commands.
Rails.application.config.after_initialize do
  context = ActiveRecord::MigrationContext.new(Rails.root.join("db/migrate"))
  if context.needs_migration?
    context.migrate
  end
end
# :nocov:
