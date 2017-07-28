class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def calendar_events_for(date)
    calendar_events.select do |event|
      if event["start"].key?("date")
        (DateTime.parse(event["start"]["date"])..DateTime.parse(event["end"]["date"])).cover?(date)
      else
        (event["start_i"]..event["end_i"]).overlaps?(date.in_time_zone("America/Denver").to_i..date.in_time_zone("America/Denver").end_of_day.to_i)
      end
    end
  end
end
