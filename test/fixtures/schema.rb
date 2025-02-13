# frozen_string_literal: true

# This file is auto-generated from the current state of the database.
#
# You can use `zee db:schema:load` to load the schema, which tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if
# those migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version
# control system.
Sequel.migration do
  change do
    create_table(:schema_migrations) do
      String :filename, size: 255, null: false

      primary_key [:filename]
    end

    create_table(:users) do
      primary_key :id
    end
  end
end
