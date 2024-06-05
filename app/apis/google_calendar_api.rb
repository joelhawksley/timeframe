# I'd love to test this, but for now I'm not as I don't want to cache my PII in VCR.
# :nocov:
class GoogleCalendarApi < Api
  def self.fetch
    result = 
      GoogleAccount.all.map do |google_account|
        google_account.fetch.values.map(&:values).flatten
      end.flatten

    save_response(result)
  end

  def self.prepare_response(response)
    response
  end

  def self.data
    if super.empty?
      []
    else
      super.map { CalendarEvent.new(**_1.symbolize_keys!) }
    end
  end
end
# :nocov: