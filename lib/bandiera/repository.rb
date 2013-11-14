class Bandiera::Repository
  def self.get(group, id)
    data = redis.get("#{group}:#{id}")

    if data
      Bandiera::Feature.new(JSON.parse(data))
    end
  end

  def self.set(feature)
    redis.set(feature.key, feature.to_json)
  end

  private

  def self.redis
    @redis ||= begin
      # TODO: use namespaced connection
      # TODO: have settings come from a config file
      Redis.new
    end
  end
end
