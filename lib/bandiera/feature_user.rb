module Bandiera
  class FeatureUser < Sequel::Model
    many_to_one :feature

    def before_create
      self.user_seed = rand(1_000_000)
    end
  end
end
