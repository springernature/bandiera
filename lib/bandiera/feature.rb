module Bandiera
  class Feature < Sequel::Model
    many_to_one :group

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

      false || enabled_for_user_groups?(opts) || enabled_for_percentage?(opts)
    end

    def report_enabled_warnings(opts = { user_group: nil, user_id: nil })
      warnings = []

      return warnings unless active?

      warnings << :user_group if user_groups_configured? && !opts[:user_group]
      warnings << :user_id if percentage_configured? && !opts[:user_id]

      warnings
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

    def enabled_for_user_groups?(opts)
      return false unless user_groups_configured? && opts[:user_group]
      user_group_within_list?(opts[:user_group]) || user_group_match_regex?(opts[:user_group])
    end

    def enabled_for_percentage?(opts)
      return false unless percentage_configured? && opts[:user_id]
      percentage_enabled_for_user?(opts[:user_id])
    end

    def feature_service
      @feature_service ||= FeatureService.new
    end

    def percentage_enabled_for_user?(user_id)
      Zlib.crc32("#{name}-1_000_000-#{user_id}") % 100 < percentage
    end

    def cleaned_user_groups_list
      user_groups_list.reject { |elm| elm.nil? || elm.empty? }.map(&:downcase)
    end

    def user_group_within_list?(user_group)
      !user_groups_list.empty? && cleaned_user_groups_list.include?(user_group.downcase)
    end

    def user_group_match_regex?(user_group)
      regexp = Regexp.new(user_groups_regex)
      !user_groups_regex.empty? && !!regexp.match(user_group)
    rescue RegexpError
      false
    end
  end
end
