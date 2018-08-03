Sequel.migration do
  change do
    alter_table(:features) do
      add_column :created_at, Time, { default: nil }
      add_column :updated_at, Time, { default: nil }
    end
  end
end
