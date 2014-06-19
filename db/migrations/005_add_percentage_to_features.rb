Sequel.migration do
  change do
    alter_table(:features) do
      add_column :percentage, Integer, { default: nil }
    end
  end
end
