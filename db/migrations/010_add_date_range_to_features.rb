Sequel.migration do
  change do
    alter_table(:features) do
      add_column :start_time, Time, { default: nil }
      add_column :end_time, Time, { default: nil }
    end
  end
end
