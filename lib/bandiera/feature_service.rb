module Bandiera
  class FeatureService
    class GroupNotFound < StandardError
      def message
        'This group does not exist in the Bandiera database.'
      end
    end

    class FeatureNotFound < StandardError
      def message
        'This feature does not exist in the Bandiera database.'
      end
    end

    def initialize(audit_log = BlackholeAuditLog.new, db = Db.connect)
      @audit_log = audit_log
      @db = db
    end

    # Groups

    def find_group(name)
      group = Group.find(name: name)
      raise GroupNotFound, "Cannot find group '#{name}'" unless group
      group
    end

    def add_group(audit_context, group)
      result = Group.find_or_create(name: group)
      @audit_log.record(audit_context, :add, :group, name: group)
      result
    end

    def fetch_groups
      Group.order(Sequel.asc(:name))
    end

    def fetch_group_features(group_name)
      find_group(group_name).features
    end

    # Features

    def fetch_feature(group, name)
      group_id = find_group_id(group)
      feature = Feature.first(group_id: group_id, name: name)
      raise FeatureNotFound, "Cannot find feature '#{name}'" unless feature
      feature
    end

    def add_feature(audit_context, data)
      data[:group] = Group.find_or_create(name: data[:group])
      lookup       = { name: data[:name], group: data[:group] }
      result = Feature.update_or_create(lookup, data)
      @audit_log.record(audit_context, :add, :feature,
        name: data[:name], group: data[:group][:name], active: data[:active])
      result
    end

    def add_features(audit_context, features)
      features.map { |feature| add_feature(audit_context, feature) }
    end

    def remove_feature(audit_context, group, name)
      group_id      = find_group_id(group)
      affected_rows = Feature.where(group_id: group_id, name: name).delete
      raise FeatureNotFound, "Cannot find feature '#{name}'" unless affected_rows > 0
      @audit_log.record(audit_context, :remove, :feature, name: name, group: group)
    end

    def update_feature(audit_context, group, name, params)
      group_id  = find_group_id(group)
      feature   = Feature.first(group_id: group_id, name: name)
      raise FeatureNotFound, "Cannot find feature '#{name}'" unless feature

      fields = {
        description: params[:description],
        active:      params[:active],
        user_groups: params[:user_groups],
        percentage:  params[:percentage],
        start_time:  params[:start_time],
        end_time:    params[:end_time]
      }.delete_if { |_k, v| v.nil? }
      result = feature.update(fields)
      @audit_log.record(audit_context, :update, :feature, name: name, group: group, fields: fields)
      result
    end

    private

    def find_group_id(name)
      group_id = Group.where(name: name).get(:id)
      raise GroupNotFound, "Cannot find group '#{name}'" unless group_id
      group_id
    end

    attr_reader :db
  end
end
