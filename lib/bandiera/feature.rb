module Bandiera
  class Feature
    attr_reader :name, :group, :description, :user_groups

    def initialize(name, group, description, enabled, user_groups={ list: [], regex: '' })
      @name        = name
      @group       = group
      @description = description
      @enabled     = enabled
      @user_groups = user_groups
    end

    def enabled?(opts={ user_group: nil })
      return false unless @enabled

      user_group = opts.fetch(:user_group, nil)

      if user_groups_configured?
        enabled = false

        if !user_groups_list.empty? && user_groups_list.include?(user_group)
          enabled = true
        end

        if !user_groups_regex.empty?
          regexp = Regexp.new(user_groups_regex)
          enabled = true if regexp.match(user_group)
        end

        enabled
      else
        true
      end
    end

    def user_groups_list
      user_groups.fetch(:list, [])
    end

    def user_groups_regex
      user_groups.fetch(:regex, '')
    end

    def user_groups_configured?
      configured = false
      configured = true unless user_groups_list.empty? && user_groups_regex.empty?
      configured
    end

    def as_json
      {
        group:       group,
        name:        name,
        description: description,
        enabled:     enabled?,
        user_groups: user_groups
      }
    end
  end
end
