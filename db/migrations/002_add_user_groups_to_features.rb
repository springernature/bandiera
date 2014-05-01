Sequel.migration do
  change do
    alter_table(:features) do
      add_column :user_groups, String, { size: 10_000, null: false, default: '{"list":[],"regex":""}' }
    end
  end
end
