Sequel.migration do
  change do
    create_table(:user_features) do
      primary_key :id
      String  :user_id,     null: false
      Integer :feature_id,  null: false
      String  :index,       null: false
      unique [:user_id, :feature_id]
    end
  end
end
