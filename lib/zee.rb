# frozen_string_literal: true

require "openssl"
require "base64"
require "rack"
require "mini_mime"
require "tilt"
require "erubi"
require "erubi/capture_block"
require "request_store"
require "superconfig"
require "yaml"
require "json"
require "securerandom"
require "i18n"
require "dry/inflector"

require_relative "zee/constants"
require_relative "zee/enum"

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "aes" => "AES",
  "cli" => "CLI",
  "html" => "HTML",
  "html_helpers" => "HTMLHelpers",
  "json_encoder" => "JSONEncoder",
  "typescript" => "TypeScript",
  "javascript" => "JavaScript",
  "sqlite3" => "SQLite3"
)
loader.ignore("#{__dir__}/sequel")
loader.setup

I18n.load_path += Dir["#{__dir__}/zee/translations/**/*.yml"]
