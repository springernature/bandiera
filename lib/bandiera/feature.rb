class Bandiera::Feature
  attr_reader :data

  def initialize(data)
    @data = sanitize_hash(data)
  end

  def key
    [data[:group], data[:name]].join(":")
  end

  def to_json
    JSON.generate(data)
  end

  def to_api
    JSON.generate({ type: data[:type], value: data[:value] })
  end

  private

  def sanitize_hash(hash)
    new_hash = {}
    hash.each do |key,value|
      new_hash[key.to_sym] = value
    end
    new_hash
  end
end
