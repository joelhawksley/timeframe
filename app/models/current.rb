# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :calendar_events

  attribute :weatherkit
  attribute :weatherkit_fetched_at
end