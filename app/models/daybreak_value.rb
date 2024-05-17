require "daybreak"

class DaybreakValue
  @@db = Daybreak::DB.new "local.db"

  def self.db
    @@db
  end

  def self.upsert(key, value)
    db[key] = value
  end

  def self.get(key)
    db[key] || {}
  end
end

  