module Bandiera
  class UserFeature < Sequel::Model
    def before_create
      self.user_seed = rand(1_000_000)
    end
  end
end
