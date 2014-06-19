Sequel.migration do
  change do
    create_table(:user_features, engine: 'InnoDB', charset: 'utf8') do
      primary_key [:user_id, :feature_id]
      String  :user_id,     null: false
      Integer :feature_id,  null: false
      String  :index,       null: false
    end
  end
end
