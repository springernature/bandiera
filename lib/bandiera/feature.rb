module Bandiera
  class Feature < Sequel::Model
    many_to_one :group

    plugin :serialization

    serialize_attributes :json, :user_groups

    alias_method :active?, :active

    def self.stub_feature(name, group)
      new(name: name, group: Group.find_or_create(name: group), description: '')
    end

    def enabled?(opts = { user_group: nil })
      return false unless active?
      return true  unless user_groups_configured?

      user_group = opts[:user_group]
      user_group_within_list?(user_group) || user_group_match_regex?(user_group)
    end

    def enabled_for_user?(user_feature)
      Zlib.crc32(user_feature.user_seed) % 100 < self.percentage
    end

    def user_groups_list
      user_groups.symbolize_keys.fetch(:list, [])
    end

    def user_groups_regex
      user_groups.symbolize_keys.fetch(:regex, '')
    end

    def user_groups_configured?
      !(user_groups_list.empty? && user_groups_regex.empty?)
    end

    def user_group_within_list?(user_group)
      !user_groups_list.empty? && cleaned_user_groups_list.include?(user_group)
    end

    def user_group_match_regex?(user_group)
      regexp = Regexp.new(user_groups_regex)
      !user_groups_regex.empty? && !!regexp.match(user_group)
    rescue RegexpError
      false
    end

    def as_v1_json
      {
        group:       group.name,
        name:        name,
        description: description,
        enabled:     enabled?
      }
    end

    def as_v2_json
      {
        group:        group.name,
        name:         name,
        description:  description,
        active:       enabled?,
        user_groups:  user_groups
      }
    end

    private

    def cleaned_user_groups_list
      user_groups_list.reject { |elm| elm.nil? || elm.empty? }
    end
  end
end
