class Feature < Ohm::Model
  attribute :name
  attribute :description
  attribute :type
  attribute :value

  reference :group, :Group

  index :name

  def to_api
    JSON.generate({ type: type, value: value })
  end
end
