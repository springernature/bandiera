module Bandiera
  class FeatureService
    class RecordNotFound < StandardError; end;

    def initialize(db=Bandiera::Db.connection)
      @db = db
    end

    def add_group(group)
      db[:groups].insert_ignore.multi_insert([{ name: group }])
    end

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
          f[:group_id] = group_name_to_id[f.delete(:group)]
          f
        end

        db[:features].on_duplicate_key_update.multi_insert(features)

        sql = <<-SQL
          SELECT
            groups.name          AS group_name,
            features.name        AS name,
            features.description AS description,
            features.enabled     AS enabled
          FROM features
          JOIN groups ON (groups.id = features.group_id)
        SQL

        db[sql].each do |f|
          if matched_names.include?("#{f[:group_name]} | #{f[:name]}")
            returned_features << Bandiera::Feature.new(
              f[:name], f[:group_name], f[:description], f[:enabled]
            )
          end
        end
      end

      returned_features
    end

    def remove_feature(group, name)
      group_id      = find_group_id(group)
      affected_rows = db[:features].where(group_id: group_id, name: name).delete
      raise RecordNotFound, "Cannot find feature '#{name}'" unless affected_rows > 0
    end

    def update_feature(group, name, params)
      db.transaction do
        curr_params = get_feature(group, name).as_json
        new_params  = curr_params.merge(params)

        remove_feature(group, name)
        add_feature(new_params)
      end
    end

    def get_groups
      db[:groups].order("name ASC").select_map(:name)
    end

    def get_group_features(group)
      group_id = find_group_id(group)

      db[:features].where(group_id: group_id).order("name ASC").map do |row|
        build_feature_from_group_and_row(group, row)
      end
    end

    def get_feature(group, name)
      group_id = find_group_id(group)
      row      = db[:features].first(group_id: group_id, name: name)
      raise RecordNotFound, "Cannot find feature '#{name}'" unless row

      build_feature_from_group_and_row(group, row)
    end

    private

    def build_feature_from_group_and_row(group, row)
      Feature.new(row[:name], group, row[:description], row[:enabled])
    end

    def find_group_id(name)
      group_id = db[:groups].where(name: name).get(:id)
      raise RecordNotFound, "Cannot find group '#{name}'" unless group_id
      group_id
    end

    attr_reader :db
  end
end
