module Bandiera
  class Group < Sequel::Model
    one_to_many :features, order: Sequel.asc(:name)
  end
end
