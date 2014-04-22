Sequel.migration do
  change do
    create_table(:groups, engine: 'InnoDB', charset: 'utf8') do
      primary_key :id
      String :name, null: false, unique: true
    end

    create_table(:features, engine: 'InnoDB', charset: 'utf8') do
      primary_key :id
      foreign_key :group_id, :groups, on_delete: :cascade
      String :name, null: false
      String :description, text: true
      TrueClass :enabled, default: false
      unique [:group_id, :name]
    end
  end
end
