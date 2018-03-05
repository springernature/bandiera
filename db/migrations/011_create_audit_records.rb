Sequel.migration do
  change do
    create_table(:audit_records) do
      primary_key :id
      Time :timestamp, null: false
      String :user, null: false
      String :action, null: false
      String :object, null: false
      String :params, text: true
    end
  end
end
