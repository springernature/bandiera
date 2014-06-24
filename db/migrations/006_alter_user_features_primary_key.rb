Sequel.migration do
  change do
    execute "ALTER TABLE `user_features` DROP PRIMARY KEY"

    alter_table(:user_features) do
      add_primary_key :id
      add_index [:user_id, :feature_id], unique: true
    end
  end
end
