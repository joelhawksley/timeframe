# frozen_string_literal: true

# :nocov:
Rails.application.config.after_initialize do
  context = ActiveRecord::MigrationContext.new(Rails.root.join("db/migrate"))
  if context.needs_migration?
    context.migrate
  end
rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
end
# :nocov:
