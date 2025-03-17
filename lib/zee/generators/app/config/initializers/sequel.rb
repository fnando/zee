# frozen_string_literal: true

Zee.app.init do
  # Connect to the database.
  Sequel.connect(config.database_url)

  # Load setup file, if it exists.
  setup_file = File.join(Dir.pwd, "db/setup.rb")
  require_relative setup_file if File.file?(setup_file)

  # Enable logging.
  if env.development?
    Sequel::Model.db.loggers.clear
    Sequel::Model.db.loggers << Logger.new("log/#{env}.log", 1, 512 * 1024)
  end

  # Enable database instrumentation.
  # Shows number of queries and total time spent on database calls for the
  # request.
  Sequel::Model.db.extension(:instrumentation) if env.development?

  # Enable plugin with localized validators.
  #
  # @see https://github.com/fnando/zee/tree/main/lib/sequel/plugins/validations.rb
  # @see https://sequel.jeremyevans.net/rdoc-plugins/classes/Sequel/Plugins/ValidationHelpers.html
  Sequel::Model.plugin :validations

  # Enable plugin that sets dirty columns.
  Sequel::Model.plugin :dirty

  # Enable plugin that adds a `{#cache_key}` method to models.
  #
  # @see https://github.com/fnando/zee/tree/main/lib/sequel/plugins/cache_key.rb
  Sequel::Model.plugin :cache_key

  # Enable plugin that sets json serializer.
  #
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

  # Enable encrypted attributes.
  Sequel::Model.plugin :encrypted_attributes

  # Set default values for columns.
  #
  # @example
  #   class User < Sequel::Model
  #     default_values name: "Anonymous"
  #   end
  Sequel::Model.plugin :defaults_setter
end
