class MemoryValue
  @@store = {}

  def self.upsert(key, value)
    @@store[key] = value
  end

  def self.get(key)
    @@store[key] || {}
  end
end
