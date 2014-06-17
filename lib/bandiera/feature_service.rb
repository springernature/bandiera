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

    def initialize(db = Db.connection)
      @db = db
    end

    def add_group(group)
      Group.find_or_create(name: group)
    end

    # TODO: add a add_groups method

    def add_feature(data)
      data[:group] = Group.find_or_create(name: data[:group])
      lookup       = { name: data[:name], group: data[:group] }
      Feature.update_or_create(lookup, data)
    end

    def add_features(features)
      returned_features = []

      db.transaction do
        matched_names = features.map { |f| "#{f[:group]} | #{f[:name]}" }

        db[:groups].insert_ignore.multi_insert(features.map { |f| { name: f[:group] } })

        group_name_to_id = {}
        db[:groups].each do |g|
          group_name_to_id[g[:name]] = g[:id]
        end

        features.map! do |f|
          f[:group_id] = group_name_to_id[f.delete(:group)]
          if f[:user_groups]
            f[:user_groups] = JSON.generate(f[:user_groups])
          else
            f[:user_groups] = '{"list":[],"regex":""}'
          end
          f
        end

        db[:features].on_duplicate_key_update.multi_insert(features)

        sql = <<-SQL
          SELECT
            groups.name          AS group_name,
            features.name        AS name,
            features.description AS description,
            features.active      AS active,
            features.user_groups AS user_groups
          FROM features
          JOIN groups ON (groups.id = features.group_id)
        SQL

        db[sql].each do |f|
          if matched_names.include?("#{f[:group_name]} | #{f[:name]}")
            returned_features << build_feature_from_group_and_row(f[:group_name], f)
          end
        end
      end

      returned_features
    end

    def remove_feature(group, name)
      group_id      = find_group_id(group)
      affected_rows = db[:features].where(group_id: group_id, name: name).delete
      fail FeatureNotFound, "Cannot find feature '#{name}'" unless affected_rows > 0
    end

    def update_feature(group, name, params)
      db.transaction do
        # FIXME: handle user_groups coming through as a hash...
        curr_params = get_feature(group, name).as_v2_json
        new_params  = curr_params.merge(params)
        remove_feature(group, name)
        add_feature(new_params)
      end
    end

    def get_groups
      Group.order(Sequel.asc(:name))
    end

    def get_group_features(group_name)
      find_group(group_name).features
    end

    def get_feature(group, name)
      group_id = find_group_id(group)
      row      = db[:features].first(group_id: group_id, name: name)
      fail FeatureNotFound, "Cannot find feature '#{name}'" unless row

      build_feature_from_group_and_row(group, row)
    end

    private

    def build_feature_from_group_and_row(group, row)
      user_groups = JSON.parse(row[:user_groups]).symbolize_keys
      Feature.new(
        name:         row[:name],
        group:        add_group(group),
        description:  row[:description],
        active:       row[:active],
        user_groups:  user_groups
      )
    end

    def find_group(name)
      group = Group.find(name: name)
      fail GroupNotFound, "Cannot find group '#{name}'" unless group
      group
    end

    def find_group_id(name)
      group_id = Group.where(name: name).get(:id)
      fail GroupNotFound, "Cannot find group '#{name}'" unless group_id
      group_id
    end

    attr_reader :db
  end
end
