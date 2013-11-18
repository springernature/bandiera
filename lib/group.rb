class Group < Ohm::Model
  attribute :name
  collection :features, :Feature
  index :name
end
