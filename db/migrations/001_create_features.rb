Sequel.migration do
  change do
    create_table(:features) do
      primary_key :id
      String :group, null: false
      String :name, null: false
      String :description, text: true
      TrueClass :value, default: false
    end
  end
end
