Sequel.migration do
  change do
    alter_table(:user_features) do
      rename_column :index, :user_seed
    end
  end
end
