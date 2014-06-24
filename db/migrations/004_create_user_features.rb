Sequel.migration do
  change do
    create_table(:user_features, engine: 'InnoDB', charset: 'utf8') do
      primary_key :id
      String  :user_id,     null: false
      Integer :feature_id,  null: false
      String  :user_seed,   null: false
      unique  [:user_id, :feature_id]
    end
  end
end
