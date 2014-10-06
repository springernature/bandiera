module Bandiera
  class Feature < Sequel::Model
    class UserGroupArgumentError < ArgumentError; end
    class UserPercentageArgumentError < ArgumentError; end

    many_to_one :group
    one_to_many :feature_users

    plugin :serialization

    serialize_attributes :json, :user_groups

    def self.stub_feature(name, group)
      new(name: name, group: Group.find_or_create(name: group), description: '')
    end

    def active?
      # work around for JRuby's SQLite connector returning numerical values instead of boolean
      return false if active == 0
      return true if active == 1
      active
    end

    def enabled?(opts = { user_group: nil, user_id: nil })
      return false unless active?
      return true  unless user_groups_configured? || percentage_configured?

      return_val = false

      if user_groups_configured?
        fail UserGroupArgumentError, 'This feature is configured for user groups - you must pass a user_group' unless opts[:user_group]
        user_group = opts[:user_group]
        return_val = (user_group_within_list?(user_group) || user_group_match_regex?(user_group))
      end

      if !return_val && percentage_configured?
        fail UserPercentageArgumentError, 'This feature is configured for a % of users - you must pass a user_id' unless opts[:user_id]
        user       = feature_service.get_feature_user(self, opts[:user_id])
        return_val = percentage_enabled_for_user?(user)
      end

      return_val
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

    def percentage_configured?
      !percentage.nil?
    end

    def as_v1_json
      {
        group:       group.name,
        name:        name,
        description: description,
        enabled:     enabled?
      }
    end

    private

    def feature_service
      @feature_service ||= FeatureService.new
    end

    def percentage_enabled_for_user?(user)
      Zlib.crc32(user.user_seed) % 100 < percentage
    end

    def cleaned_user_groups_list
      user_groups_list.reject { |elm| elm.nil? || elm.empty? }
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
  end
end
