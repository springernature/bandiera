module Bandiera
  class UserFeature < Sequel::Model
    def before_create
      self.index = rand(1_000_000)
    end
  end
end
