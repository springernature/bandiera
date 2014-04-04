module Bandiera
  class FeatureService
    class RecordNotFound < StandardError; end

    def initialize(db = Bandiera::Db.connection)
      @db = db
    end

    # TODO: make Group a first-class object and have this return the created group
    def add_group(group)
      db[:groups].insert_ignore.multi_insert([{ name: group }])
    end

    # TODO: add a add_groups method

    def add_feature(feature)
      add_features([feature]).first
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
          f[:group_id]    = group_name_to_id[f.delete(:group)]
          f[:user_groups] = JSON.generate(f[:user_groups]) if f[:user_groups]
          f
        end

        db[:features].on_duplicate_key_update.multi_insert(features)

        sql = <<-SQL
          SELECT
            groups.name          AS group_name,
            features.name        AS name,
            features.description AS description,
            features.enabled     AS enabled,
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
      # FIXME: raise a more specific error class - i.e. FeatureRecordNotFound
      fail RecordNotFound, "Cannot find feature '#{name}'" unless affected_rows > 0
    end

    def update_feature(group, name, params)
      db.transaction do
        curr_params = get_feature(group, name).as_json
        new_params  = curr_params.merge(params)

        remove_feature(group, name)
        add_feature(new_params)
      end
    end

    # TODO: return group objects
    def get_groups
      db[:groups].order('name ASC').select_map(:name)
    end

    def get_group_features(group)
      group_id = find_group_id(group)

      db[:features].where(group_id: group_id).order('name ASC').map do |row|
        build_feature_from_group_and_row(group, row)
      end
    end

    def get_feature(group, name)
      group_id = find_group_id(group)
      row      = db[:features].first(group_id: group_id, name: name)
      # FIXME: raise a more specific error class - i.e. FeatureRecordNotFound
      fail RecordNotFound, "Cannot find feature '#{name}'" unless row

      build_feature_from_group_and_row(group, row)
    end

    private

    def build_feature_from_group_and_row(group, row)
      user_groups = JSON.parse(row[:user_groups]).symbolize_keys
      Feature.new(row[:name], group, row[:description], row[:enabled], user_groups)
    end

    def find_group_id(name)
      group_id = db[:groups].where(name: name).get(:id)
      # FIXME: raise a more specific error class - i.e. GroupRecordNotFound
      fail RecordNotFound, "Cannot find group '#{name}'" unless group_id
      group_id
    end

    attr_reader :db
  end
end
