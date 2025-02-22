# frozen_string_literal: true

App.init do
  # Connect to the database.
  Sequel.connect(config.database_url)

  # Enable logging.
  Sequel::Model.db.loggers.clear
  Sequel::Model.db.loggers << Logger.new($stdout) if env.development?

  # Enable plugin that sets timestamp columns.
  Sequel::Model.plugin :timestamps, update_on_create: true

  # Enable plugin that sets dirty columns.
  Sequel::Model.plugin :dirty

  # Enable plugin that sets json serializer.
  # @example
  #   User.first.to_json
  Sequel::Model.plugin :json_serializer

  # Enable plugin that strips leading and trailing whitespaces from strings.
  Sequel::Model.plugin :string_stripper

  # Enable plugin that adds SQL comments to queries.
  if env.development?
    Sequel::Model.db.extension(:sql_comments)
    Sequel::Model.plugin :sql_comments
  end

  # Set default values for columns.
  # @example
  #   class User < Sequel::Model
  #     default_values name: "Anonymous"
  #   end
  Sequel::Model.plugin :defaults_setter
end
